variable "aws_region" {
  description = "AWS region for the production portfolio infrastructure."
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
  default     = "prod"

  validation {
    condition     = var.environment == "prod"
    error_message = "The production environment must use environment = prod."
  }
}

variable "github_username" {
  description = "GitHub username used in resource tags."
  type        = string
  default     = "2aron41"
}

variable "bucket_name" {
  description = "Existing production S3 bucket name."
  type        = string
}

variable "enable_versioning" {
  description = "Whether production S3 versioning should be enabled."
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Whether production S3 default encryption should be managed."
  type        = bool
  default     = true
}

variable "enable_cloudfront" {
  description = "Whether the existing production CloudFront, OAC, and bucket policy should be represented."
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "Default object CloudFront returns for root requests."
  type        = string
  default     = "index.html"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class matching the current production distribution."
  type        = string
  default     = "PriceClass_All"
}

variable "cloudfront_allowed_methods" {
  description = "CloudFront methods matching the existing production distribution."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cloudfront_cache_policy_id" {
  description = "Cache policy ID matching the existing production CloudFront distribution."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudfront_tags" {
  description = "CloudFront-specific tags matching the existing production distribution."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "cloudfront_comment" {
  description = "Comment matching the existing production CloudFront distribution."
  type        = string
  default     = ""
}

variable "cloudfront_origin_id" {
  description = "Origin ID matching the existing production CloudFront distribution."
  type        = string
}

variable "cloudfront_oac_name" {
  description = "Name matching the existing production Origin Access Control."
  type        = string
}

variable "cloudfront_oac_description" {
  description = "Description matching the existing production Origin Access Control."
  type        = string
  default     = "Created by CloudFront"
}

variable "cloudfront_source_arn_condition_test" {
  description = "Bucket-policy SourceArn condition operator matching production."
  type        = string
  default     = "ArnLike"
}

variable "purpose" {
  description = "Purpose tag for the production portfolio infrastructure."
  type        = string
  default     = "Production portfolio website"
}
