mock_provider "aws" {}

run "disabled_by_default" {
  command = plan

  assert {
    condition     = output.enabled == false
    error_message = "Inquiry workload must be disabled by default."
  }

  assert {
    condition     = output.api_endpoint == null
    error_message = "API endpoint must be null while inquiry workload is disabled."
  }

  assert {
    condition     = output.lambda_function_name == null
    error_message = "Lambda function name must be null while inquiry workload is disabled."
  }

  assert {
    condition     = output.sns_topic_arn == null
    error_message = "SNS topic ARN must be null while inquiry workload is disabled."
  }
}

run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [
    var.environment,
  ]
}

run "sns_topic_absent_when_disabled" {
  command = plan

  assert {
    condition     = length(aws_sns_topic.inquiry) == 0
    error_message = "Inquiry SNS topic must not exist while the workload is disabled."
  }
}

run "sns_topic_created_when_enabled" {
  command = plan

  variables {
    enable_inquiry = true
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
  }

  assert {
    condition     = length(aws_sns_topic.inquiry) == 1
    error_message = "Exactly one inquiry SNS topic must exist when enabled."
  }

  assert {
    condition     = aws_sns_topic.inquiry[0].name == "portfolio-test-dev-inquiries"
    error_message = "Inquiry SNS topic name is incorrect."
  }

  assert {
    condition     = aws_sns_topic.inquiry[0].tags["Project"] == "portfolio-test"
    error_message = "Project tag is incorrect."
  }

  assert {
    condition     = aws_sns_topic.inquiry[0].tags["Environment"] == "dev"
    error_message = "Environment tag is incorrect."
  }

  assert {
    condition     = aws_sns_topic.inquiry[0].tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy tag is incorrect."
  }

  assert {
    condition     = aws_sns_topic.inquiry[0].tags["Owner"] == "2aron41"
    error_message = "Owner tag is incorrect."
  }

  assert {
    condition     = aws_sns_topic.inquiry[0].tags["Purpose"] == "Portfolio inquiry service"
    error_message = "Purpose tag is incorrect."
  }
}
