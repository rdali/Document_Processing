variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS Region to be deployed in"
  type        = string
}

variable "s3_bucket_inputs_name" {
  description = "Name of S3 bucket for inputs"
  type        = string
}


variable "s3_bucket_outputs_name" {
  description = "Name of S3 bucket for outputs"
  type        = string
}

variable "lambda_role_bda_arn" {
  description = "ARN of the IAM role for the BDA trigger Lambda function"
  type        = string
}

variable "input_bucket_arn" {
  description = "ARN of the input S3 bucket"
  type        = string
}

variable "output_bucket_arn" {
  description = "ARN of the output S3 bucket"
  type        = string
}

variable "data_automation_project_arn"{
  description = "ARN of BDA project"
  type        = string
}

variable "bda_blueprint_arn"{
  description = "ARN of BDA blueprint"
  type        = string
}

