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
    condition = toset(
      aws_cloudfront_distribution.this[0].default_cache_behavior[0].allowed_methods
    ) == toset(["GET", "HEAD", "OPTIONS"])
    error_message = "CloudFront should allow GET, HEAD, and OPTIONS by default."
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
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_5xx) == 0
    error_message = "CloudFront 5xx alarm should remain disabled unless explicitly enabled."
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


run "plan_cloudfront_5xx_alarm" {
  command = plan

  variables {
    bucket_name                 = "day30-cloudfront-alarm-test"
    environment                 = "dev"
    enable_versioning           = true
    enable_encryption           = true
    enable_cloudfront           = true
    enable_cloudfront_5xx_alarm = true

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  assert {
    condition     = length(aws_sns_topic.cloudfront_alerts) == 0
    error_message = "SNS notification topic should remain disabled unless notifications are explicitly enabled."
  }


  assert {
    condition     = length(aws_sns_topic_policy.cloudfront_alerts) == 0
    error_message = "SNS topic policy should remain disabled when notifications are disabled."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_5xx[0].alarm_actions) == 0
    error_message = "CloudFront alarm should have no alarm actions when notifications are disabled."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_5xx[0].ok_actions) == 0
    error_message = "CloudFront alarm should have no OK actions when notifications are disabled."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_5xx) == 1
    error_message = "Exactly one CloudFront 5xx alarm should be planned when monitoring is enabled."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].alarm_name == "day30-cloudfront-alarm-test-cloudfront-5xx-error-rate"
    error_message = "CloudFront 5xx alarm should use the expected deterministic name."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].namespace == "AWS/CloudFront"
    error_message = "Alarm should monitor the AWS/CloudFront namespace."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].metric_name == "5xxErrorRate"
    error_message = "Alarm should monitor CloudFront 5xxErrorRate."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].statistic == "Average"
    error_message = "CloudFront 5xx alarm should use the Average statistic."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].period == 300
    error_message = "CloudFront 5xx alarm should use five-minute periods."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].threshold == 5
    error_message = "CloudFront 5xx alarm threshold should be 5 percent."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].evaluation_periods == 3
    error_message = "CloudFront 5xx alarm should evaluate three periods."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].datapoints_to_alarm == 2
    error_message = "CloudFront 5xx alarm should require two breaching datapoints."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].comparison_operator == "GreaterThanOrEqualToThreshold"
    error_message = "CloudFront 5xx alarm should trigger at or above the configured threshold."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].treat_missing_data == "notBreaching"
    error_message = "Missing CloudFront datapoints should be treated as non-breaching."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_5xx[0].dimensions["Region"] == "Global"
    error_message = "CloudFront alarm should use the Global metric dimension."
  }
}

run "plan_cloudfront_alarm_notifications" {
  command = plan

  override_resource {
    target = aws_sns_topic.cloudfront_alerts[0]

    values = {
      arn = "arn:aws:sns:us-east-1:123456789012:day31-notification-test-cloudfront-alerts"
    }

    override_during = plan
  }

  variables {
    bucket_name                           = "day31-notification-test"
    environment                           = "dev"
    enable_versioning                     = true
    enable_encryption                     = true
    enable_cloudfront                     = true
    enable_cloudfront_5xx_alarm           = true
    enable_cloudfront_alarm_notifications = true

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  assert {
    condition     = length(aws_sns_topic.cloudfront_alerts) == 1
    error_message = "Exactly one SNS notification topic should be planned when notifications are enabled."
  }


  assert {
    condition     = length(aws_sns_topic_policy.cloudfront_alerts) == 1
    error_message = "Exactly one SNS topic policy should be planned when notifications are enabled."
  }

  assert {
    condition     = aws_sns_topic.cloudfront_alerts[0].name == "day31-notification-test-cloudfront-alerts"
    error_message = "SNS topic should use the expected deterministic name."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_5xx[0].alarm_actions) == 1
    error_message = "CloudFront alarm should have exactly one ALARM notification action."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_5xx[0].ok_actions) == 1
    error_message = "CloudFront alarm should have exactly one recovery notification action."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.cloudfront_5xx[0].alarm_actions,
      aws_sns_topic.cloudfront_alerts[0].arn
    )
    error_message = "CloudFront ALARM action should target the SNS notification topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.cloudfront_5xx[0].ok_actions,
      aws_sns_topic.cloudfront_alerts[0].arn
    )
    error_message = "CloudFront OK action should target the SNS notification topic."
  }
}

run "plan_production_compatible_cloudfront_methods" {
  command = plan

  variables {
    bucket_name                = "day26-prod-methods-test"
    environment                = "prod"
    s3_bucket_tags             = {}
    enable_versioning          = false
    enable_encryption          = true
    enable_cloudfront          = true
    default_root_object        = "index.html"
    cloudfront_price_class     = "PriceClass_All"
    cloudfront_allowed_methods = ["GET", "HEAD"]
    cloudfront_cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cloudfront_tags = {
      Name = "aaron-portfolio-cdn"
    }
    cloudfront_comment                   = ""
    cloudfront_origin_id                 = "existing-production-origin-id"
    cloudfront_oac_name                  = "existing-production-oac-name"
    cloudfront_oac_description           = "Created by CloudFront"
    cloudfront_policy_id                 = "PolicyForCloudFrontPrivateContent"
    cloudfront_policy_version            = "2008-10-17"
    cloudfront_policy_sid                = "AllowCloudFrontServicePrincipal"
    cloudfront_source_arn_condition_test = "ArnLike"

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "prod"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "production-import-planning"
    }
  }

  assert {
    condition = toset(
      aws_cloudfront_distribution.this[0].default_cache_behavior[0].allowed_methods
    ) == toset(["GET", "HEAD"])
    error_message = "Production-compatible CloudFront configuration should allow only GET and HEAD."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].default_cache_behavior[0].cache_policy_id == "658327ea-f89d-4fab-a63d-7e88639e58f6"
    error_message = "Production-compatible CloudFront configuration should preserve the existing cache policy."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].tags["Name"] == "aaron-portfolio-cdn"
    error_message = "Production-compatible CloudFront configuration should preserve the existing Name tag."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this[0].tags) == 1
    error_message = "Production-compatible CloudFront configuration should not adopt additional CloudFront tags during import reconciliation."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].price_class == "PriceClass_All"
    error_message = "Production-compatible CloudFront configuration should use PriceClass_All."
  }

  assert {
    condition     = length(aws_s3_bucket.this.tags) == 0
    error_message = "Production-compatible configuration should preserve the existing untagged S3 bucket during import reconciliation."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Disabled"
    error_message = "Production-compatible configuration should keep versioning disabled before import."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].comment == ""
    error_message = "Production-compatible CloudFront configuration should preserve the empty production comment."
  }

  assert {
    condition = one([
      for origin in aws_cloudfront_distribution.this[0].origin :
      origin.origin_id
    ]) == "existing-production-origin-id"
    error_message = "CloudFront should use the configured production origin ID."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].default_cache_behavior[0].target_origin_id == "existing-production-origin-id"
    error_message = "The default cache behavior should target the configured production origin ID."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this[0].name == "existing-production-oac-name"
    error_message = "Origin Access Control should use the configured production name."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this[0].description == "Created by CloudFront"
    error_message = "Origin Access Control should preserve the configured production description."
  }

  assert {
    condition     = data.aws_iam_policy_document.cloudfront_s3_read[0].policy_id == "PolicyForCloudFrontPrivateContent"
    error_message = "Production-compatible policy should preserve the existing policy ID."
  }

  assert {
    condition     = data.aws_iam_policy_document.cloudfront_s3_read[0].version == "2008-10-17"
    error_message = "Production-compatible policy should preserve the existing policy language version."
  }

  assert {
    condition     = data.aws_iam_policy_document.cloudfront_s3_read[0].statement[0].sid == "AllowCloudFrontServicePrincipal"
    error_message = "Production-compatible policy should preserve the existing statement ID."
  }

  assert {
    condition     = var.cloudfront_source_arn_condition_test == "ArnLike"
    error_message = "The production-compatible bucket policy should use an ArnLike SourceArn condition."
  }
}

run "reject_invalid_cloudfront_allowed_method" {
  command = plan

  variables {
    bucket_name                = "day26-invalid-method-test"
    environment                = "dev"
    enable_cloudfront          = true
    cloudfront_allowed_methods = ["GET", "HEAD", "POST"]

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.cloudfront_allowed_methods,
  ]
}


run "reject_invalid_source_arn_condition_test" {
  command = plan

  variables {
    bucket_name                          = "day27-invalid-condition-test"
    environment                          = "dev"
    enable_cloudfront                    = true
    cloudfront_source_arn_condition_test = "StringLike"

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.cloudfront_source_arn_condition_test,
  ]
}

run "reject_empty_cloudfront_origin_id" {
  command = plan

  variables {
    bucket_name          = "day27-empty-origin-test"
    environment          = "dev"
    enable_cloudfront    = true
    cloudfront_origin_id = "   "

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.cloudfront_origin_id,
  ]
}

run "reject_empty_cloudfront_oac_name" {
  command = plan

  variables {
    bucket_name         = "day27-empty-oac-test"
    environment         = "dev"
    enable_cloudfront   = true
    cloudfront_oac_name = ""

    tags = {
      Project     = "aws-serverless-portfolio"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "Aaron"
      Purpose     = "terraform-testing"
    }
  }

  expect_failures = [
    var.cloudfront_oac_name,
  ]
}
