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

variable "bda_standard_output_configuration" {
  description = "Standard output is pre-defined extraction managed by Bedrock. It can extract information from documents, images, videos, and audio."
  type        = object({
    audio    = optional(object({
      extraction = optional(object({
        category = optional(object({
          state = optional(string)
          types = optional(list(string))
        }))
      }))
      generative_field = optional(object({
        state = optional(string)
        types = optional(list(string))
      }))
    }))
    document = optional(object({
      extraction = optional(object({
        bounding_box = optional(object({
          state = optional(string)
        }))
        granularity = optional(object({
          types = optional(list(string))
        }))
      }))
      generative_field = optional(object({
        state = optional(string)
      }))
      output_format = optional(object({
        additional_file_format = optional(object({
          state = optional(string)
        }))
        text_format = optional(object({
          types = optional(list(string))
        }))
      }))
    }))
    image    = optional(object({
      extraction = optional(object({
        category = optional(object({
          state = optional(string)
          types = optional(list(string))
        }))
        bounding_box = optional(object({
          state = optional(string)
        }))
      }))
      generative_field = optional(object({
        state = optional(string)
        types = optional(list(string))
      }))
    }))
    video    = optional(object({
      extraction = optional(object({
        category = optional(object({
          state = optional(string)
          types = optional(list(string))
        }))
        bounding_box = optional(object({
          state = optional(string)
        }))
      }))
      generative_field = optional(object({
        state = optional(string)
        types = optional(list(string))
      }))
    }))
  })
  default = null
 }