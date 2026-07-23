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

  bucket_name       = var.bucket_name
  enable_versioning = true

  tags = merge(local.common_tags, {
    Purpose = "Terraform practice"
    Owner   = var.github_username
  })
}
