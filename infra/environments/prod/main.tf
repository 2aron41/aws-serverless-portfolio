provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "static_site" {
  source = "../../modules/static-site"

  bucket_name                          = var.bucket_name
  environment                          = var.environment
  s3_bucket_tags                       = var.s3_bucket_tags
  enable_versioning                    = var.enable_versioning
  enable_encryption                    = var.enable_encryption
  enable_cloudfront                    = var.enable_cloudfront
  enable_cloudfront_5xx_alarm          = var.enable_cloudfront_5xx_alarm
  default_root_object                  = var.default_root_object
  cloudfront_price_class               = var.cloudfront_price_class
  cloudfront_allowed_methods           = var.cloudfront_allowed_methods
  cloudfront_cache_policy_id           = var.cloudfront_cache_policy_id
  cloudfront_tags                      = var.cloudfront_tags
  cloudfront_comment                   = var.cloudfront_comment
  cloudfront_origin_id                 = var.cloudfront_origin_id
  cloudfront_oac_name                  = var.cloudfront_oac_name
  cloudfront_oac_description           = var.cloudfront_oac_description
  cloudfront_policy_id                 = var.cloudfront_policy_id
  cloudfront_policy_version            = var.cloudfront_policy_version
  cloudfront_policy_sid                = var.cloudfront_policy_sid
  cloudfront_source_arn_condition_test = var.cloudfront_source_arn_condition_test

  tags = merge(local.common_tags, {
    Purpose = var.purpose
    Owner   = var.github_username
  })
}
