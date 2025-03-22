resource "aws_iam_role" "textract_trigger" {
  name = "${var.project_name}-textract-trigger"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "textract.amazonaws.com"]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "textract_trigger" {
  name = "${var.project_name}-textract-trigger"
  role = aws_iam_role.textract_trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "textract:StartExpenseAnalysis",
          "textract:StartDocumentAnalysis",
          "textract:GetDocumentAnalysis",
          "textract:GetExpenseAnalysis",
          "sns:Publish",
          "iam:PassRole",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          var.s3_bucket_raw_arn,
          "${var.s3_bucket_raw_arn}/*",
          var.s3_bucket_processed_arn,
          "${var.s3_bucket_processed_arn}/*",
          var.sns_topic_arn,
          var.sqs_queue_arn,
          "arn:aws:logs:*:*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "textract:StartExpenseAnalysis",
          "textract:StartDocumentAnalysis",
          "textract:GetDocumentAnalysis",
          "textract:GetExpenseAnalysis"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AmazonTextractServiceRole managed policy to the trigger role
resource "aws_iam_role_policy_attachment" "textract_service_role" {
  role       = aws_iam_role.textract_trigger.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonTextractServiceRole"
}

# IAM role for Textract processor Lambda
resource "aws_iam_role" "textract_process" {
  name = "${var.project_name}-textract-process"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Textract processor Lambda
resource "aws_iam_role_policy" "textract_processor" {
  name = "${var.project_name}-textract-process"
  role = aws_iam_role.textract_process.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "textract:GetExpenseAnalysis",
          "s3:GetObject",
          "s3:PutObject",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sns:Publish",
          "sns:Subscribe",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sagemaker:StartHumanLoop",
          "sagemaker:StopHumanLoop",
          "sagemaker:DescribeHumanLoop"
        ]
        Resource = [
          "*",  # For Textract GetExpenseAnalysis
          var.s3_bucket_raw_arn,
          "${var.s3_bucket_raw_arn}/*",
          var.s3_bucket_processed_arn,
          "${var.s3_bucket_processed_arn}/*",
          var.textract_results_queue_arn,
          var.sns_topic_arn,
          "arn:aws:logs:*:*:*",
          var.a2i_private_flow_arn
        ]
      }
    ]
  })
}
