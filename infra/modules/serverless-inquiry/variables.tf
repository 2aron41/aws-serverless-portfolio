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

variable "allowed_origin" {
  description = "HTTPS browser origin allowed to submit portfolio inquiries."
  type        = string
  default     = ""

  validation {
    condition = (
      var.allowed_origin == ""
      ||
      can(
        regex(
          "^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?$",
          var.allowed_origin,
        )
      )
    )
    error_message = "allowed_origin must be empty or a single HTTPS origin without a path."
  }
}

variable "enable_operational_alarms" {
  description = "Whether to create CloudWatch operational alarms for the inquiry workload."
  type        = bool
  default     = false
}

variable "operational_alarm_topic_arn" {
  description = "Optional SNS topic ARN for inquiry operational ALARM and OK notifications."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.operational_alarm_topic_arn == null ||
      can(regex("^arn:aws[a-zA-Z-]*:sns:[a-z0-9-]+:[0-9]{12}:[A-Za-z0-9_-]+$", var.operational_alarm_topic_arn))
    )
    error_message = "operational_alarm_topic_arn must be null or a valid SNS topic ARN."
  }
}
