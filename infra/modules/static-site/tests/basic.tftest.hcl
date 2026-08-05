# Goal
# Test the static-site module with safe sample inputs and confirm the module accepts valid configuration.

mock_provider "aws" {
  override_during = plan

  mock_resource "aws_s3_bucket" {
    defaults = {
      id = "day16-static-site-test"
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      id          = "DAY24MOCKDISTRIBUTION"
      arn         = "arn:aws:cloudfront::123456789012:distribution/DAY24MOCKDISTRIBUTION"
      domain_name = "day24-mock.cloudfront.net"
    }
  }

  mock_resource "aws_cloudfront_origin_access_control" {
    defaults = {
      id = "DAY24MOCKOAC"
    }
  }
}

run "valid_static_site_configuration" {
  command = plan

  variables {
    bucket_name       = "day16-static-site-test"
    environment       = "dev"
    enable_versioning = true

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "day16-static-site-test"
    error_message = "The module did not accept the expected bucket name."
  }

  assert {
    condition     = output.bucket_name == "day16-static-site-test"
    error_message = "The bucket_name output did not return the expected bucket name."
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "The module did not accept the dev environment."
  }

  assert {
    condition = alltrue([
      for key in ["Project", "Environment", "ManagedBy", "Owner", "Purpose"] :
      trimspace(lookup(var.tags, key, "")) != ""
    ])
    error_message = "One or more required tags are missing."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "S3 versioning was not enabled."
  }

  assert {
    condition     = var.enable_encryption
    error_message = "S3 encryption should default to enabled."
  }

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.this) == 1
    error_message = "The S3 encryption configuration resource was not created."
  }

  assert {
    condition = try(
      one(
        aws_s3_bucket_server_side_encryption_configuration.this[0].rule
      ).apply_server_side_encryption_by_default[0].sse_algorithm,
      ""
    ) == "AES256"
    error_message = "S3 default encryption must use the AES256 SSE-S3 algorithm."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "All four S3 public-access protections must remain enabled."
  }

  assert {
    condition     = !var.enable_cloudfront
    error_message = "CloudFront must remain disabled by default."
  }

  assert {
    condition     = length(aws_cloudfront_origin_access_control.this) == 0
    error_message = "Origin Access Control must not be created when CloudFront is disabled."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this) == 0
    error_message = "CloudFront distribution must not be created when CloudFront is disabled."
  }

  assert {
    condition     = length(aws_s3_bucket_policy.cloudfront) == 0
    error_message = "CloudFront bucket policy must not be created when CloudFront is disabled."
  }

  assert {
    condition = (
      output.cloudfront_distribution_id == null &&
      output.cloudfront_domain_name == null &&
      output.origin_access_control_id == null
    )
    error_message = "CloudFront outputs must be null when CloudFront is disabled."
  }
}

run "reject_empty_bucket_name" {
  command = plan

  variables {
    bucket_name       = ""
    environment       = "dev"
    enable_versioning = true

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.bucket_name,
  ]
}

run "reject_uppercase_bucket_name" {
  command = plan

  variables {
    bucket_name       = "Day16-Invalid-Bucket"
    environment       = "dev"
    enable_versioning = true

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.bucket_name,
  ]
}

run "reject_unsupported_environment" {
  command = plan

  variables {
    bucket_name       = "day16-staging-test"
    environment       = "staging"
    enable_versioning = true

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "staging"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.environment,
  ]
}

run "reject_missing_required_tag" {
  command = plan

  variables {
    bucket_name       = "day16-missing-tag-test"
    environment       = "dev"
    enable_versioning = true

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
    }
  }

  expect_failures = [
    var.tags,
  ]
}

run "reject_empty_default_root_object" {
  command = plan

  variables {
    bucket_name            = "day20-empty-root-test"
    environment            = "dev"
    enable_versioning      = true
    enable_cloudfront      = false
    default_root_object    = ""
    cloudfront_price_class = "PriceClass_100"

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.default_root_object,
  ]
}

run "reject_invalid_cloudfront_price_class" {
  command = plan

  variables {
    bucket_name            = "day20-invalid-price-test"
    environment            = "dev"
    enable_versioning      = true
    enable_cloudfront      = false
    default_root_object    = "index.html"
    cloudfront_price_class = "PriceClass_300"

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.cloudfront_price_class,
  ]
}

run "plan_cloudfront_when_enabled" {
  command = plan

  variables {
    bucket_name            = "day22-cloudfront-plan-test"
    environment            = "dev"
    enable_versioning      = true
    enable_encryption      = true
    enable_cloudfront      = true
    default_root_object    = "index.html"
    cloudfront_price_class = "PriceClass_100"

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  assert {
    condition     = length(aws_cloudfront_origin_access_control.this) == 1
    error_message = "Exactly one Origin Access Control should be planned when CloudFront is enabled."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this) == 1
    error_message = "Exactly one CloudFront distribution should be planned when CloudFront is enabled."
  }

  assert {
    condition     = length(aws_s3_bucket_policy.cloudfront) == 1
    error_message = "Exactly one CloudFront S3 bucket policy should be planned when CloudFront is enabled."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].default_root_object == "index.html"
    error_message = "CloudFront should use index.html as the default root object."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].price_class == "PriceClass_100"
    error_message = "CloudFront should use the expected price class."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "CloudFront should redirect viewers from HTTP to HTTPS."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this[0].signing_behavior == "always"
    error_message = "Origin Access Control should always sign requests."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this[0].signing_protocol == "sigv4"
    error_message = "Origin Access Control should use SigV4."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this[0].origin_access_control_origin_type == "s3"
    error_message = "Origin Access Control should be configured for S3."
  }

  assert {
    condition     = output.cloudfront_distribution_id != null
    error_message = "CloudFront distribution ID output should not be null when CloudFront is enabled."
  }

  assert {
    condition     = output.cloudfront_domain_name != null
    error_message = "CloudFront domain output should not be null when CloudFront is enabled."
  }

  assert {
    condition     = output.origin_access_control_id != null
    error_message = "Origin Access Control output should not be null when CloudFront is enabled."
  }
}
