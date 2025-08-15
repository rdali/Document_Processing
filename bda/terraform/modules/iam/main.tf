data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_lambda_trigger_bda" {
  name               =  "${var.project_name}-role-lambda-trigger-bda-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Add CloudWatch Logs policy
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.project_name}-lambda-logs-${var.env}"
  role = aws_iam_role.iam_lambda_trigger_bda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project_name}-*"
        ]
      }
    ]
  })
}

# Add S3 read/write policy
resource "aws_iam_role_policy" "bda_lambda_write_s3" {
  name = "${var.project_name}-lambda-s3-${var.env}"
  role = aws_iam_role.iam_lambda_trigger_bda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.input_bucket_arn,
          "${var.input_bucket_arn}/*",
          var.output_bucket_arn,
          "${var.output_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Add Bedrock BDA policy
resource "aws_iam_role_policy" "lambda_bedrock_bda" {
  name = "${var.project_name}-lambda-bedrock-bda-${var.env}"
  role = aws_iam_role.iam_lambda_trigger_bda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "bedrock:CreateDataAutomationProject",
            "bedrock:UpdateDataAutomationProject",
            "bedrock:GetDataAutomationProject",
            "bedrock:GetDataAutomationStatus",
            "bedrock:ListDataAutomationProjects",
            "bedrock:InvokeDataAutomationAsync"
        ]
        Resource = "*"
      }
    ]
  })
}
