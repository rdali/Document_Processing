resource "aws_cognito_user_pool" "workforce" {
    name = "${var.project_name}-a2i-workforce-pool"

    admin_create_user_config {
      allow_admin_create_user_only = true  # This is the key setting
      
    }

    # Password policy
    password_policy {
        minimum_length                   = 8
        require_lowercase                = true
        require_numbers                  = true
        require_symbols                  = true
        require_uppercase                = true
        temporary_password_validity_days = 7
    }

    # MFA configuration
    mfa_configuration = "OFF"

    # Account recovery setting
    account_recovery_setting {
        recovery_mechanism {
        name     = "verified_email"
        priority = 1
        }
    }

    # Email configuration
    email_configuration {
        email_sending_account = "COGNITO_DEFAULT"
    }

    # Username attributes
    username_attributes = ["email"]
    
    # Auto verified attributes
    auto_verified_attributes = ["email"]

    # Schema attributes
    schema {
        name                = "email"
        attribute_data_type = "String"
        required            = true
        mutable            = true

        string_attribute_constraints {
        min_length = 7
        max_length = 256
        }
    }

  lifecycle {
      ignore_changes = [
        admin_create_user_config
      ]
    }

}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-a2i"
  user_pool_id = aws_cognito_user_pool.workforce.id
}

resource "aws_cognito_user_pool_client" "workforce_client" {
  name         = "${var.project_name}-a2i-workforce-app-client"
  user_pool_id = aws_cognito_user_pool.workforce.id
  generate_secret     = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  supported_identity_providers = ["COGNITO"]
  callback_urls = ["https://example.com"] 
  logout_urls = ["https://example.com"]

  lifecycle {
    ignore_changes = [
      callback_urls,
      logout_urls
    ]
  }

}


resource "aws_cognito_user_group" "default" {
  name         = "${var.project_name}-a2i-workforce-pool-default"
  user_pool_id = aws_cognito_user_pool.workforce.id
  description  = "Managed by Terraform"
}


resource "aws_iam_role" "a2i_flow" {
  name               = "${var.project_name}-a2i-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["sagemaker.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  lifecycle {
    prevent_destroy = false
  }
}

# Create IAM policy for A2I
resource "aws_iam_policy" "this" {
  name = "${var.project_name}-a2i-policy"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "sagemaker:*",
          "cognito-idp:*"
        ]
        Resource = [
          "arn:aws:s3:::${var.processed_bucket}",
          "arn:aws:s3:::${var.processed_bucket}/*",
          "arn:aws:s3:::${var.raw_bucket}",
          "arn:aws:s3:::${var.raw_bucket}/*",
          aws_cognito_user_pool.workforce.arn,
          "${aws_cognito_user_pool.workforce.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.a2i_flow.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_role_policy_attachment" "sagemaker" {
  role       = aws_iam_role.a2i_flow.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Create IAM policy for A2I flow
resource "aws_iam_role_policy" "a2i_flow_policy" {
  name = "${var.project_name}-a2i-flow"
  role = aws_iam_role.a2i_flow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.processed_bucket}",
          "arn:aws:s3:::${var.processed_bucket}/*"
        ]
      }
    ]
  })
}


resource "aws_sagemaker_workforce" "this" {
  workforce_name = "${var.project_name}-a2i-workforce"

  cognito_config {
    client_id = aws_cognito_user_pool_client.workforce_client.id
    user_pool = aws_cognito_user_pool.workforce.id
  }
}

resource "aws_sagemaker_workteam" "this" {
  workteam_name  = "${var.project_name}-a2i-workteam"
  workforce_name = aws_sagemaker_workforce.this.id
  description    = "${var.project_name}-a2i-workteam"

  member_definition {
    cognito_member_definition {
      client_id  = aws_cognito_user_pool_client.workforce_client.id
      user_pool  = aws_cognito_user_pool.workforce.id
      user_group = "${var.project_name}-a2i-workforce-pool-default"
    }
  }
}

resource "aws_sagemaker_human_task_ui" "this" {
  human_task_ui_name = "${var.project_name}-template-ui"

  ui_template {
    content = file("${path.root}/../src/ui_template/expense_ui_template.html")
  }
}

resource "time_sleep" "wait1" {
  depends_on = [ aws_sagemaker_human_task_ui.this ]

  create_duration = "30s"
}


resource "aws_sagemaker_flow_definition" "private" {
  flow_definition_name = "${var.project_name}-a2i-private"
  role_arn             = aws_iam_role.a2i_flow.arn

  human_loop_config {
    human_task_ui_arn                     = aws_sagemaker_human_task_ui.this.arn
    task_availability_lifetime_in_seconds = var.private_task_availability_lifetime_in_seconds
    task_count                            = 1
    task_description                      = "Human Validation task"
    task_title                            = "Human Validation task"
    workteam_arn                          = aws_sagemaker_workteam.this.arn
  }

  output_config {
    s3_output_path = "s3://${var.processed_bucket}/a2i-results/"
  }
  
  depends_on = [ time_sleep.wait1 ]
}

resource "aws_cognito_user" "this" {
    for_each = var.aws_cognito_users

    user_pool_id = aws_cognito_user_pool.workforce.id
    username     = each.value

    attributes = {
        email          = each.value
        email_verified = true
    }
}


resource "aws_cognito_user_in_group" "this" {
  for_each = aws_cognito_user.this

  user_pool_id = aws_cognito_user_pool.workforce.id
  group_name   = aws_cognito_user_group.default.name
  username     = each.value.username
}


