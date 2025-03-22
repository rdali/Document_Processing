variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for S3 notifications"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the SQS queue for S3 notifications"
  type        = string
}

variable "enable_cors" {
  description = "Enable CORS for the S3 buckets"
  type        = bool
  default     = false
} 