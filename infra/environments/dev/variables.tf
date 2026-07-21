variable "aws_region" {
  description = "AWS region for the portfolio infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming and tagging resources."
  type        = string
  default     = "aws-serverless-portfolio"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "github_username" {
  description = "GitHub username used in dev resource naming and tags."
  type        = string
  default     = "2aron41"
}
