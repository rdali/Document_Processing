variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "document-processor"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "create_state_iam_policy" {
  description = "Whether to create the IAM policy for Terraform state access"
  type        = bool
  default     = false
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket-rdali"
}

variable "state_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-table-rdali"
}
