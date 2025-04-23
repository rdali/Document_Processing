variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the Lambda function"
  type        = string
}

variable "s3_bucket_raw_arn" {
  description = "ARN of the raw S3 bucket"
  type        = string
}

variable "s3_bucket_processed_arn" {
  description = "ARN of the processed S3 bucket"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  type        = string
}

variable "textract_results_queue_arn" {
  description = "ARN of the Textract results SQS queue"
  type        = string
}

variable "s3_bucket_processed_bucket" {
  description = "Name of the processed S3 bucket"
  type        = string
}

variable "s3_bucket_raw_bucket" {
  description = "Name of the raw S3 bucket"
  type        = string
}

variable "a2i_private_flow_arn" {
  description = "ARN of the A2I private flow definition"
  type        = string
}
