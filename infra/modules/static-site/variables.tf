variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must use lowercase letters, numbers, periods, or hyphens and must begin and end with a letter or number."
  }
}

variable "environment" {
  description = "Environment represented by the static-site resources."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "enable_versioning" {
  description = "Whether S3 versioning should be enabled."
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Whether default S3 server-side encryption should be explicitly managed."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the static site resources."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "ManagedBy", "Owner", "Purpose"] :
      trimspace(lookup(var.tags, key, "")) != ""
    ])
    error_message = "Tags must include non-empty Project, Environment, ManagedBy, Owner, and Purpose values."
  }
}

variable "enable_cloudfront" {
  description = "Whether to create a CloudFront distribution for the static site."
  type        = bool
  default     = false
}

variable "default_root_object" {
  description = "Default object CloudFront should return for root requests."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(trimspace(var.default_root_object)) > 0
    error_message = "Default root object cannot be empty."
  }
}

variable "cloudfront_price_class" {
  description = "CloudFront price class for edge locations."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition = contains([
      "PriceClass_100",
      "PriceClass_200",
      "PriceClass_All"
    ], var.cloudfront_price_class)

    error_message = "CloudFront price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}
