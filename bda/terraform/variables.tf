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

variable "bda_project_description"{
  description = "BDA project Description"
  type        = string
}

variable "blueprint_schema_file" {
  description = "The file containing the schema for the blueprint."
  type        = string
  default     = null
}

variable "blueprint_type" {
  description = "The modality type of the blueprint."
  type        = string
  default     = "DOCUMENT"

  validation {
    condition     = var.blueprint_type == "DOCUMENT" || var.blueprint_type == "IMAGE"
    error_message = "Blueprint type must be DOCUMENT or IMAGE."
  }
}

