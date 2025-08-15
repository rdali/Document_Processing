variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "bda_project_description"{
  description = "BDA project Description"
  type        = string
}

variable "blueprint_schema" {
  description = "The schema for the blueprint."
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