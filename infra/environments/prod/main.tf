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

  bucket_name                = var.bucket_name
  environment                = var.environment
  enable_versioning          = var.enable_versioning
  enable_encryption          = var.enable_encryption
  enable_cloudfront          = var.enable_cloudfront
  default_root_object        = var.default_root_object
  cloudfront_price_class     = var.cloudfront_price_class
  cloudfront_allowed_methods = var.cloudfront_allowed_methods

  tags = merge(local.common_tags, {
    Purpose = var.purpose
    Owner   = var.github_username
  })
}
