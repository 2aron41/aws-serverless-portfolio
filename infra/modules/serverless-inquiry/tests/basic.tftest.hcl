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


  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-inquiry-exec"
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

run "lambda_absent_when_disabled" {
  command = plan

  assert {
    condition     = length(data.archive_file.inquiry_lambda) == 0
    error_message = "Lambda archive must not be built when inquiry is disabled."
  }

  assert {
    condition     = length(aws_lambda_function.inquiry) == 0
    error_message = "Lambda function must not exist when inquiry is disabled."
  }
}

run "lambda_configuration_when_enabled" {
  command = plan

  variables {
    enable_inquiry = true
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
  }

  assert {
    condition     = length(data.archive_file.inquiry_lambda) == 1
    error_message = "Exactly one Lambda archive must be created."
  }

  assert {
    condition     = length(aws_lambda_function.inquiry) == 1
    error_message = "Exactly one Lambda function must exist."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].function_name
      == "portfolio-test-dev-inquiry"
    )
    error_message = "Lambda function name is incorrect."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].handler
      == "inquiry_handler.lambda_handler"
    )
    error_message = "Lambda handler is incorrect."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].runtime
      == "python3.12"
    )
    error_message = "Lambda runtime must be Python 3.12."
  }

  assert {
    condition = (
      length(
        aws_lambda_function.inquiry[0].architectures
      ) == 1
      &&
      contains(
        aws_lambda_function.inquiry[0].architectures,
        "x86_64",
      )
    )
    error_message = "Lambda architecture must be exactly x86_64."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].memory_size
      == 128
    )
    error_message = "Lambda memory must be 128 MB."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].timeout
      == 5
    )
    error_message = "Lambda timeout must be 5 seconds."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].reserved_concurrent_executions
      == 2
    )
    error_message = "Lambda reserved concurrency must be 2."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].role
      == "arn:aws:iam::123456789012:role/mock-inquiry-exec"
    )
    error_message = "Lambda must use the dedicated execution role."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0]
      .environment[0]
      .variables["INQUIRY_TOPIC_ARN"]
      == "arn:aws:sns:us-east-1:123456789012:mock-inquiries"
    )
    error_message = "Lambda must receive only the inquiry SNS topic ARN."
  }

  assert {
    condition = (
      data.archive_file.inquiry_lambda[0].output_base64sha256
      != ""
    )
    error_message = "Lambda package hash must be generated."
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].source_code_hash
      == data.archive_file.inquiry_lambda[0].output_base64sha256
    )
    error_message = "Lambda source hash must match the deployment package."
  }
}
