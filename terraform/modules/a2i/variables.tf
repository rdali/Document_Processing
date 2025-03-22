variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "processed_bucket" {
  description = "Name of the processed S3 bucket"
  type        = string
}

variable "private_task_availability_lifetime_in_seconds" {
  description = "Time in seconds that a task remains available to Human workers"
  type        = number
  default     = 3600  # 1 hour
} 