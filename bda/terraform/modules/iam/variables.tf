variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "input_bucket_arn"{
  description = "S3 input bucket ARN"
  type        = string
}

variable "output_bucket_arn"{
  description = "S3 output bucket ARN"
  type        = string
}
