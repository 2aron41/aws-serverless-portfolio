provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  workload_tags = merge(local.common_tags, {
    Purpose = var.purpose
    Owner   = var.github_username
  })

  production_s3_tags = merge(
    var.s3_bucket_tags == null ? {} : var.s3_bucket_tags,
    local.workload_tags,
  )

  production_cloudfront_tags = merge(
    var.cloudfront_tags == null ? {} : var.cloudfront_tags,
    local.workload_tags,
  )
}

module "static_site" {
  source = "../../modules/static-site"

  bucket_name                           = var.bucket_name
  environment                           = var.environment
  s3_bucket_tags                        = local.production_s3_tags
  enable_versioning                     = var.enable_versioning
  enable_encryption                     = var.enable_encryption
  enable_cloudfront                     = var.enable_cloudfront
  enable_cloudfront_5xx_alarm           = var.enable_cloudfront_5xx_alarm
  enable_cloudfront_alarm_notifications = var.enable_cloudfront_alarm_notifications
  default_root_object                   = var.default_root_object
  cloudfront_price_class                = var.cloudfront_price_class
  cloudfront_allowed_methods            = var.cloudfront_allowed_methods
  cloudfront_cache_policy_id            = var.cloudfront_cache_policy_id
  cloudfront_tags                       = local.production_cloudfront_tags
  cloudfront_comment                    = var.cloudfront_comment
  cloudfront_origin_id                  = var.cloudfront_origin_id
  cloudfront_oac_name                   = var.cloudfront_oac_name
  cloudfront_oac_description            = var.cloudfront_oac_description
  cloudfront_policy_id                  = var.cloudfront_policy_id
  cloudfront_policy_version             = var.cloudfront_policy_version
  cloudfront_policy_sid                 = var.cloudfront_policy_sid
  cloudfront_policy_source_arn          = var.cloudfront_policy_source_arn
  cloudfront_source_arn_condition_test  = var.cloudfront_source_arn_condition_test

  tags = local.workload_tags
}

module "serverless_inquiry" {
  source = "../../modules/serverless-inquiry"

  enable_inquiry = var.enable_inquiry
  project_name   = var.project_name
  environment    = var.environment
  owner          = var.github_username

  log_retention_days = var.inquiry_log_retention_days

  # The current production portfolio is served directly from CloudFront.
  # Derive the browser origin from the managed distribution rather than
  # maintaining a second copy of the production domain.
  allowed_origin = (
    var.enable_inquiry && var.enable_cloudfront
    ? "https://${module.static_site.cloudfront_domain_name}"
    : ""
  )
}
