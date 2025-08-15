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

variable "extensions" {
  type        = map(string)
  default = {
    "pdf document" = ".pdf"
  }
}

variable "lambda_trigger_bda_arn" {
  description = "ARN of the Lambda trigger BDA function"
  type        = string
}
