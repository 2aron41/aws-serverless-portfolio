mock_provider "aws" {
  override_during = plan

  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-east-1:123456789012:mock-inquiries"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/mock-inquiry"
    }
  }
}

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

run "lambda_iam_absent_when_disabled" {
  command = plan

  assert {
    condition     = length(aws_iam_role.inquiry_lambda) == 0
    error_message = "Lambda IAM role must not exist while inquiry is disabled."
  }

  assert {
    condition     = length(aws_iam_role_policy.inquiry_lambda) == 0
    error_message = "Lambda IAM policy must not exist while inquiry is disabled."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.inquiry_lambda) == 0
    error_message = "Lambda log group must not exist while inquiry is disabled."
  }
}

run "lambda_iam_is_least_privilege_when_enabled" {
  command = plan

  variables {
    enable_inquiry     = true
    project_name       = "portfolio-test"
    environment        = "dev"
    owner              = "2aron41"
    log_retention_days = 14
  }

  assert {
    condition     = length(aws_iam_role.inquiry_lambda) == 1
    error_message = "Exactly one Lambda execution role must exist."
  }

  assert {
    condition     = length(aws_iam_role_policy.inquiry_lambda) == 1
    error_message = "Exactly one Lambda inline policy must exist."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.inquiry_lambda) == 1
    error_message = "Exactly one Lambda log group must exist."
  }

  assert {
    condition     = aws_iam_role.inquiry_lambda[0].name == "portfolio-test-dev-inquiry-exec"
    error_message = "Lambda execution role name is incorrect."
  }

  assert {
    condition = (
      jsondecode(
        aws_iam_role.inquiry_lambda[0].assume_role_policy
      ).Statement[0].Principal.Service
      == "lambda.amazonaws.com"
    )
    error_message = "Only the Lambda service should assume the execution role."
  }

  assert {
    condition = (
      jsondecode(
        aws_iam_role.inquiry_lambda[0].assume_role_policy
      ).Statement[0].Action
      == "sts:AssumeRole"
    )
    error_message = "Lambda trust policy must allow only sts:AssumeRole."
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.inquiry_lambda[0].name
      == "/aws/lambda/portfolio-test-dev-inquiry"
    )
    error_message = "Lambda log group name is incorrect."
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.inquiry_lambda[0].retention_in_days
      == 14
    )
    error_message = "Lambda log retention must be 14 days."
  }

  assert {
    condition = (
      jsondecode(
        aws_iam_role_policy.inquiry_lambda[0].policy
      ).Statement[0].Action
      == "sns:Publish"
    )
    error_message = "Lambda policy must allow SNS Publish."
  }

  assert {
    condition = (
      jsondecode(
        aws_iam_role_policy.inquiry_lambda[0].policy
      ).Statement[0].Resource
      == aws_sns_topic.inquiry[0].arn
    )
    error_message = "SNS Publish must target only the inquiry topic."
  }

  assert {
    condition = contains(
      jsondecode(
        aws_iam_role_policy.inquiry_lambda[0].policy
      ).Statement[1].Action,
      "logs:CreateLogStream",
    )
    error_message = "Lambda must be able to create its log stream."
  }

  assert {
    condition = contains(
      jsondecode(
        aws_iam_role_policy.inquiry_lambda[0].policy
      ).Statement[1].Action,
      "logs:PutLogEvents",
    )
    error_message = "Lambda must be able to write log events."
  }

  assert {
    condition = !contains(
      jsondecode(
        aws_iam_role_policy.inquiry_lambda[0].policy
      ).Statement[1].Action,
      "logs:CreateLogGroup",
    )
    error_message = "Lambda must not receive unnecessary CreateLogGroup permission."
  }
}

run "reject_invalid_log_retention" {
  command = plan

  variables {
    log_retention_days = 10
  }

  expect_failures = [
    var.log_retention_days,
  ]
}
