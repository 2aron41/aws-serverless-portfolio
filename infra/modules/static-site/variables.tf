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

variable "s3_bucket_tags" {
  description = "Optional S3 bucket-specific tag override. Null uses the module-wide tags."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "cloudfront_allowed_methods" {
  description = "HTTP methods CloudFront allows for the default cache behavior."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]

  validation {
    condition = (
      length(var.cloudfront_allowed_methods) > 0 &&
      alltrue([
        for method in var.cloudfront_allowed_methods :
        contains(["GET", "HEAD", "OPTIONS"], method)
      ]) &&
      contains(var.cloudfront_allowed_methods, "GET") &&
      contains(var.cloudfront_allowed_methods, "HEAD")
    )
    error_message = "CloudFront allowed methods must contain GET and HEAD and may optionally contain OPTIONS."
  }
}

variable "cloudfront_cache_policy_id" {
  description = "Optional CloudFront cache policy ID. When null, the module uses the legacy forwarded_values configuration."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.cloudfront_cache_policy_id == null ||
      length(trimspace(var.cloudfront_cache_policy_id)) > 0
    )
    error_message = "CloudFront cache policy ID must be null or a non-empty string."
  }
}

variable "cloudfront_tags" {
  description = "Optional CloudFront-specific tag override. Null uses the module-wide tags."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "cloudfront_comment" {
  description = "Comment assigned to the CloudFront distribution. Null uses the module-generated default."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudfront_origin_id" {
  description = "Origin ID used by the CloudFront distribution. Null uses the module-generated default."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.cloudfront_origin_id == null ||
      length(trimspace(var.cloudfront_origin_id)) > 0
    )
    error_message = "CloudFront origin ID must be null or a non-empty string."
  }
}

variable "cloudfront_oac_name" {
  description = "Name assigned to the CloudFront Origin Access Control. Null uses the module-generated default."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.cloudfront_oac_name == null ||
      length(trimspace(var.cloudfront_oac_name)) > 0
    )
    error_message = "CloudFront OAC name must be null or a non-empty string."
  }
}

variable "cloudfront_oac_description" {
  description = "Description assigned to the CloudFront Origin Access Control. Null uses the module-generated default."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudfront_source_arn_condition_test" {
  description = "Condition operator used to restrict S3 access to the CloudFront distribution ARN."
  type        = string
  default     = "StringEquals"

  validation {
    condition = contains(
      ["StringEquals", "ArnLike"],
      var.cloudfront_source_arn_condition_test
    )
    error_message = "CloudFront SourceArn condition test must be StringEquals or ArnLike."
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
