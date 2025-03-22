# Get current AWS account ID
data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "trigger_textract" {
  name                       = "${var.project_name}-trigger-textract"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 60
  delay_seconds             = 0
  receive_wait_time_seconds = 20
}

resource "aws_sns_topic" "textract_results" {
  name = "AmazonTextract-${var.project_name}-results"
}

# Create the second SQS queue for Textract results
resource "aws_sqs_queue" "textract_results" {
  name                       = "${var.project_name}-textract-process"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 60
}

# Subscribe the queue to the SNS topic
resource "aws_sns_topic_subscription" "textract_results" {
  topic_arn = aws_sns_topic.textract_results.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.textract_results.arn
}

# Allow SNS to send messages to SQS
resource "aws_sqs_queue_policy" "textract_results" {
  queue_url = aws_sqs_queue.textract_results.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowSNSToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.textract_results.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn": aws_sns_topic.textract_results.arn
          }
        }
      }
    ]
  })
}

# Add SNS topic policy to allow Textract to publish
resource "aws_sns_topic_policy" "textract_results" {
  arn = aws_sns_topic.textract_results.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowTextractToPublish"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:AddPermission",
          "SNS:Subscribe"
        ]
        Resource = aws_sns_topic.textract_results.arn
      }
    ]
  })
} 
