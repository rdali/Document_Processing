# IAM Role for Bedrock Process Lambda
resource "aws_iam_role" "bedrock_trigger" {
  name = "${var.project_name}-bedrock-trigger-role"

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

# IAM policy for Bedrock Process Lambda
resource "aws_iam_policy" "bedrock_trigger_policy" {
  name = "${var.project_name}-bedrock-trigger-policy"
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
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_raw_arn,
          "${var.s3_bucket_raw_arn}/*",
          var.s3_bucket_processed_arn,
          "${var.s3_bucket_processed_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to Bedrock Trigger role
resource "aws_iam_role_policy_attachment" "bedrock_trigger_attachment" {
  role       = aws_iam_role.bedrock_trigger.name
  policy_arn = aws_iam_policy.bedrock_trigger_policy.arn
}
