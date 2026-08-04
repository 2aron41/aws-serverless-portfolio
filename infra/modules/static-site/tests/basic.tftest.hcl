# Goal
# Test the static-site module with safe sample inputs and confirm the module accepts valid configuration.

mock_provider "aws" {
  override_during = plan

  mock_resource "aws_s3_bucket" {
    defaults = {
      id = "day16-static-site-test"
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
