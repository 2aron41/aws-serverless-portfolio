variable "enable_inquiry" {
  description = "Whether to create the serverless inquiry workload."
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Project name used for inquiry workload naming and tags."
  type        = string
  default     = "aws-serverless-portfolio"

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "owner" {
  description = "Owner tag value for the inquiry workload."
  type        = string
  default     = "2aron41"

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the inquiry Lambda."
  type        = number
  default     = 14

  validation {
    condition = contains(
      [7, 14, 30, 60, 90],
      var.log_retention_days,
    )
    error_message = "log_retention_days must be 7, 14, 30, 60, or 90."
  }
}
