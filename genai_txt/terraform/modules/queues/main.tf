# Get current AWS account ID
data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "trigger_textract" {
  name                       = "${var.project_name}-trigger-textract"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 60
  delay_seconds             = 0
  receive_wait_time_seconds = 20
}