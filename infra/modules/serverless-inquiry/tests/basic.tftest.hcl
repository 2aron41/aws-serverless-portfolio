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


  mock_resource "aws_lambda_function" {
    defaults = {
      invoke_arn = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:mock-inquiry/invocations"
      version    = "1"
    }
  }

  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      id            = "mockapi123"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:mockapi123"
      api_endpoint  = "https://mockapi123.execute-api.us-east-1.amazonaws.com"
    }
  }

  mock_resource "aws_apigatewayv2_integration" {
    defaults = {
      id = "mock-integration-id"
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
    allowed_origin = "https://portfolio.example"
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
    allowed_origin     = "https://portfolio.example"
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
    allowed_origin = "https://portfolio.example"
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
      == -1
    )
    error_message = "Lambda must use unreserved concurrency."
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

run "http_api_absent_when_disabled" {
  command = plan

  assert {
    condition     = length(aws_apigatewayv2_api.inquiry) == 0
    error_message = "HTTP API must not exist when inquiry is disabled."
  }

  assert {
    condition     = length(aws_apigatewayv2_integration.inquiry) == 0
    error_message = "HTTP API integration must not exist when inquiry is disabled."
  }

  assert {
    condition     = length(aws_apigatewayv2_route.inquiry) == 0
    error_message = "HTTP API route must not exist when inquiry is disabled."
  }

  assert {
    condition     = length(aws_apigatewayv2_stage.inquiry) == 0
    error_message = "HTTP API stage must not exist when inquiry is disabled."
  }

  assert {
    condition     = length(aws_lambda_permission.inquiry_api) == 0
    error_message = "API Gateway Lambda permission must not exist when inquiry is disabled."
  }
}

run "http_api_configuration_when_enabled" {
  command = plan

  variables {
    enable_inquiry = true
    allowed_origin = "https://portfolio.example"
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
  }

  assert {
    condition     = length(aws_apigatewayv2_api.inquiry) == 1
    error_message = "Exactly one HTTP API must exist."
  }

  assert {
    condition = (
      aws_apigatewayv2_api.inquiry[0].protocol_type
      == "HTTP"
    )
    error_message = "Inquiry API must be an HTTP API."
  }

  assert {
    condition = (
      length(
        aws_apigatewayv2_api.inquiry[0]
        .cors_configuration[0]
        .allow_origins
      ) == 1
      &&
      contains(
        aws_apigatewayv2_api.inquiry[0]
        .cors_configuration[0]
        .allow_origins,
        "https://portfolio.example",
      )
    )
    error_message = "CORS must allow exactly the configured portfolio origin."
  }

  assert {
    condition = (
      length(
        aws_apigatewayv2_api.inquiry[0]
        .cors_configuration[0]
        .allow_methods
      ) == 1
      &&
      contains(
        aws_apigatewayv2_api.inquiry[0]
        .cors_configuration[0]
        .allow_methods,
        "POST",
      )
    )
    error_message = "CORS must allow only POST."
  }

  assert {
    condition = (
      length(
        aws_apigatewayv2_api.inquiry[0]
        .cors_configuration[0]
        .allow_headers
      ) == 1
      &&
      contains(
        aws_apigatewayv2_api.inquiry[0]
        .cors_configuration[0]
        .allow_headers,
        "content-type",
      )
    )
    error_message = "CORS must allow only content-type."
  }

  assert {
    condition = (
      aws_apigatewayv2_integration.inquiry[0]
      .integration_type
      == "AWS_PROXY"
    )
    error_message = "Lambda integration must use AWS_PROXY."
  }

  assert {
    condition = (
      aws_apigatewayv2_integration.inquiry[0]
      .integration_method
      == "POST"
    )
    error_message = "Lambda integration method must be POST."
  }

  assert {
    condition = (
      aws_apigatewayv2_integration.inquiry[0]
      .payload_format_version
      == "2.0"
    )
    error_message = "HTTP API must use payload format 2.0."
  }

  assert {
    condition = (
      aws_apigatewayv2_integration.inquiry[0]
      .timeout_milliseconds
      == 5000
    )
    error_message = "API integration timeout must be 5000 ms."
  }

  assert {
    condition = (
      aws_apigatewayv2_route.inquiry[0].route_key
      == "POST /inquiries"
    )
    error_message = "Only POST /inquiries should be configured."
  }

  assert {
    condition = (
      aws_apigatewayv2_route.inquiry[0].authorization_type
      == "NONE"
    )
    error_message = "Inquiry route must be publicly callable."
  }

  assert {
    condition = (
      aws_apigatewayv2_route.inquiry[0].target
      == "integrations/mock-integration-id"
    )
    error_message = "Route must target the Lambda integration."
  }

  assert {
    condition = (
      aws_apigatewayv2_stage.inquiry[0].name
      == "$default"
    )
    error_message = "HTTP API must use the default stage."
  }

  assert {
    condition = (
      aws_apigatewayv2_stage.inquiry[0].auto_deploy
      == true
    )
    error_message = "HTTP API default stage must auto-deploy."
  }

  assert {
    condition = (
      aws_apigatewayv2_stage.inquiry[0]
      .default_route_settings[0]
      .throttling_burst_limit
      == 2
    )
    error_message = "HTTP API burst throttle must be 2."
  }

  assert {
    condition = (
      aws_apigatewayv2_stage.inquiry[0]
      .default_route_settings[0]
      .throttling_rate_limit
      == 1
    )
    error_message = "HTTP API rate throttle must be 1 request per second."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api[0].principal
      == "apigateway.amazonaws.com"
    )
    error_message = "Only API Gateway should receive invoke permission."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api[0].action
      == "lambda:InvokeFunction"
    )
    error_message = "Permission must allow only Lambda invocation."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api[0].source_arn
      == "arn:aws:execute-api:us-east-1:123456789012:mockapi123/$default/POST/inquiries"
    )
    error_message = "Invoke permission must be scoped to default-stage POST /inquiries."
  }

  assert {
    condition = (
      output.api_endpoint
      == "https://mockapi123.execute-api.us-east-1.amazonaws.com/inquiries"
    )
    error_message = "API output must resolve to /inquiries."
  }
}

run "reject_insecure_allowed_origin" {
  command = plan

  variables {
    allowed_origin = "http://portfolio.example"
  }

  expect_failures = [
    var.allowed_origin,
  ]
}

run "api_access_logging_absent_when_disabled" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_log_group.inquiry_api_access) == 0
    error_message = "API access log group must not exist while inquiry is disabled."
  }
}

run "api_access_logging_is_privacy_safe_when_enabled" {
  command = plan

  variables {
    enable_inquiry     = true
    allowed_origin     = "https://portfolio.example"
    project_name       = "portfolio-test"
    environment        = "dev"
    owner              = "2aron41"
    log_retention_days = 14
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.inquiry_api_access) == 1
    error_message = "Exactly one API access log group must exist."
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.inquiry_api_access[0].name
      == "/aws/apigateway/portfolio-test-dev-inquiry-access"
    )
    error_message = "API access log group name is incorrect."
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.inquiry_api_access[0].retention_in_days
      == 14
    )
    error_message = "API access logs must use the configured retention period."
  }

  assert {
    condition = (
      length(
        aws_apigatewayv2_stage.inquiry[0].access_log_settings
      ) == 1
    )
    error_message = "HTTP API stage must have access logging enabled."
  }

  assert {
    condition = (
      aws_apigatewayv2_stage.inquiry[0]
      .access_log_settings[0]
      .destination_arn
      == aws_cloudwatch_log_group.inquiry_api_access[0].arn
    )
    error_message = "HTTP API access logs must use the dedicated log group."
  }

  assert {
    condition = (
      jsondecode(
        aws_apigatewayv2_stage.inquiry[0]
        .access_log_settings[0]
        .format
      ).requestId
      == "$context.requestId"
    )
    error_message = "Access log format must contain the API Gateway request ID."
  }

  assert {
    condition = (
      toset(
        keys(
          jsondecode(
            aws_apigatewayv2_stage.inquiry[0]
            .access_log_settings[0]
            .format
          )
        )
      )
      ==
      toset([
        "requestId",
        "requestTimeEpoch",
        "httpMethod",
        "routeKey",
        "status",
        "responseLength",
        "integrationLatency",
        "responseLatency",
        "integrationStatus",
      ])
    )
    error_message = "API access logs must contain only the approved metadata fields."
  }

  assert {
    condition = !can(
      regex(
        "body|email|message|sourceip|useragent|querystring|integrationerrormessage",
        lower(
          aws_apigatewayv2_stage.inquiry[0]
          .access_log_settings[0]
          .format
        ),
      )
    )
    error_message = "API access logs must not contain visitor content or sensitive request metadata."
  }
}


run "inquiry_operational_alarms_disabled_by_default" {
  command = plan

  variables {
    enable_inquiry = true
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
    allowed_origin = "https://example.com"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_lambda_errors) == 0
    error_message = "Lambda error alarm must remain disabled by default."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_lambda_throttles) == 0
    error_message = "Lambda throttle alarm must remain disabled by default."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_api_5xx) == 0
    error_message = "API 5xx alarm must remain disabled by default."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_api_4xx) == 0
    error_message = "API 4xx alarm must remain disabled by default."
  }
}


run "inquiry_operational_alarms_enabled_without_notifications" {
  command = plan

  override_resource {
    target = aws_apigatewayv2_api.inquiry[0]

    values = {
      id            = "mock-inquiry-api-id"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:mock-inquiry-api-id"
    }

    override_during = plan
  }

  variables {
    enable_inquiry            = true
    enable_operational_alarms = true
    project_name              = "portfolio-test"
    environment               = "dev"
    owner                     = "2aron41"
    allowed_origin            = "https://example.com"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_lambda_errors) == 1
    error_message = "Exactly one Lambda error alarm must be created."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_lambda_throttles) == 1
    error_message = "Exactly one Lambda throttle alarm must be created."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_api_5xx) == 1
    error_message = "Exactly one API 5xx alarm must be created."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.inquiry_api_4xx) == 1
    error_message = "Exactly one API 4xx alarm must be created."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].alarm_name
      == "portfolio-test-dev-inquiry-lambda-errors"
    )
    error_message = "Lambda error alarm name is incorrect."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].namespace
      == "AWS/Lambda"
    )
    error_message = "Lambda error alarm must use AWS/Lambda."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].metric_name
      == "Errors"
    )
    error_message = "Lambda error alarm must monitor Errors."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].statistic
      == "Sum"
    )
    error_message = "Lambda error alarm must use Sum."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].period
      == 300
    )
    error_message = "Lambda error alarm must use a five-minute period."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].threshold
      == 1
    )
    error_message = "Lambda error alarm threshold must be one."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].evaluation_periods
      == 1
    )
    error_message = "Lambda error alarm must evaluate one period."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].datapoints_to_alarm
      == 1
    )
    error_message = "Lambda error alarm must require one breaching datapoint."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].comparison_operator
      == "GreaterThanOrEqualToThreshold"
    )
    error_message = "Lambda error alarm comparison operator is incorrect."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].treat_missing_data
      == "notBreaching"
    )
    error_message = "Lambda error alarm must treat missing data as not breaching."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0]
      .dimensions["FunctionName"]
      == "portfolio-test-dev-inquiry"
    )
    error_message = "Lambda error alarm must target the inquiry Lambda."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].namespace
      == "AWS/Lambda"
    )
    error_message = "Lambda throttle alarm must use AWS/Lambda."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].metric_name
      == "Throttles"
    )
    error_message = "Lambda throttle alarm must monitor Throttles."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].threshold
      == 1
    )
    error_message = "Lambda throttle alarm threshold must be one."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0]
      .treat_missing_data
      == "notBreaching"
    )
    error_message = "Lambda throttle alarm must treat missing data as not breaching."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0]
      .dimensions["FunctionName"]
      == "portfolio-test-dev-inquiry"
    )
    error_message = "Lambda throttle alarm must target the inquiry Lambda."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].namespace
      == "AWS/ApiGateway"
    )
    error_message = "API 5xx alarm must use AWS/ApiGateway."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].metric_name
      == "5xx"
    )
    error_message = "API alarm must monitor 5xx."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].statistic
      == "Sum"
    )
    error_message = "API 5xx alarm must use Sum."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].threshold
      == 1
    )
    error_message = "API 5xx alarm threshold must be one."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].evaluation_periods
      == 1
    )
    error_message = "API 5xx alarm must evaluate one period."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].datapoints_to_alarm
      == 1
    )
    error_message = "API 5xx alarm must require one breaching datapoint."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].treat_missing_data
      == "notBreaching"
    )
    error_message = "API 5xx alarm must treat missing data as not breaching."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].dimensions["ApiId"]
      == "mock-inquiry-api-id"
    )
    error_message = "API 5xx alarm must target the inquiry HTTP API."
  }

  assert {
    condition = (
      length(
        aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].alarm_actions
      )
      == 0
    )
    error_message = "Lambda error alarm must have no notification action without a topic ARN."
  }

  assert {
    condition = (
      length(
        aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].ok_actions
      )
      == 0
    )
    error_message = "Lambda error alarm must have no recovery action without a topic ARN."
  }

  assert {
    condition = (
      length(
        aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].alarm_actions
      )
      == 0
    )
    error_message = "Lambda throttle alarm must have no notification action without a topic ARN."
  }

  assert {
    condition = (
      length(
        aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].alarm_actions
      )
      == 0
    )
    error_message = "API 5xx alarm must have no notification action without a topic ARN."
  }
}


run "inquiry_operational_alarms_enabled_with_notifications" {
  command = plan

  variables {
    enable_inquiry              = true
    enable_operational_alarms   = true
    operational_alarm_topic_arn = "arn:aws:sns:us-east-1:123456789012:portfolio-operations"
    project_name                = "portfolio-test"
    environment                 = "dev"
    owner                       = "2aron41"
    allowed_origin              = "https://example.com"
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].alarm_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "Lambda error ALARM action must target the operational topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].ok_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "Lambda error OK action must target the operational topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].alarm_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "Lambda throttle ALARM action must target the operational topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].ok_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "Lambda throttle OK action must target the operational topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].alarm_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "API 5xx ALARM action must target the operational topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].ok_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "API 5xx OK action must target the operational topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].alarm_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "API 4xx ALARM action must target the operational topic."
  }

  assert {
    condition = contains(
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].ok_actions,
      "arn:aws:sns:us-east-1:123456789012:portfolio-operations",
    )
    error_message = "API 4xx OK action must target the operational topic."
  }

}


run "reject_invalid_operational_alarm_topic_arn" {
  command = plan

  variables {
    operational_alarm_topic_arn = "not-an-sns-arn"
  }

  expect_failures = [
    var.operational_alarm_topic_arn,
  ]
}


run "operational_alarm_outputs_disabled" {
  command = plan

  variables {
    enable_inquiry = true
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
    allowed_origin = "https://example.com"
  }

  assert {
    condition     = output.lambda_error_alarm_arn == null
    error_message = "Lambda error alarm ARN must be null when operational alarms are disabled."
  }

  assert {
    condition     = output.lambda_throttle_alarm_arn == null
    error_message = "Lambda throttle alarm ARN must be null when operational alarms are disabled."
  }

  assert {
    condition     = output.api_5xx_alarm_arn == null
    error_message = "API 5xx alarm ARN must be null when operational alarms are disabled."
  }

  assert {
    condition     = length(output.operational_alarm_arns) == 0
    error_message = "Operational alarm ARN list must be empty when alarms are disabled."
  }

  assert {
    condition     = output.api_4xx_alarm_arn == null
    error_message = "API 4xx alarm ARN output must be null when operational alarms are disabled."
  }

}


run "operational_alarm_outputs_enabled" {
  command = plan

  override_resource {
    target = aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0]

    values = {
      arn = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-lambda-errors"
    }

    override_during = plan
  }

  override_resource {
    target = aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0]

    values = {
      arn = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-lambda-throttles"
    }

    override_during = plan
  }

  override_resource {
    target = aws_cloudwatch_metric_alarm.inquiry_api_5xx[0]

    values = {
      arn = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-api-5xx"
    }

    override_during = plan
  }


  override_resource {
    target = aws_cloudwatch_metric_alarm.inquiry_api_4xx[0]

    values = {
      arn = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-api-4xx"
    }

    override_during = plan
  }

  variables {
    enable_inquiry            = true
    enable_operational_alarms = true
    project_name              = "portfolio-test"
    environment               = "dev"
    owner                     = "2aron41"
    allowed_origin            = "https://example.com"
  }

  assert {
    condition = (
      output.lambda_error_alarm_arn
      == "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-lambda-errors"
    )
    error_message = "Lambda error alarm ARN output is incorrect."
  }

  assert {
    condition = (
      output.lambda_throttle_alarm_arn
      == "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-lambda-throttles"
    )
    error_message = "Lambda throttle alarm ARN output is incorrect."
  }

  assert {
    condition = (
      output.api_5xx_alarm_arn
      == "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-api-5xx"
    )
    error_message = "API 5xx alarm ARN output is incorrect."
  }

  assert {
    condition     = length(output.operational_alarm_arns) == 4
    error_message = "Exactly four operational alarm ARNs must be exported."
  }

  assert {
    condition = contains(
      output.operational_alarm_arns,
      "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-lambda-errors",
    )
    error_message = "Operational alarm outputs must contain the Lambda error alarm."
  }

  assert {
    condition = contains(
      output.operational_alarm_arns,
      "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-lambda-throttles",
    )
    error_message = "Operational alarm outputs must contain the Lambda throttle alarm."
  }

  assert {
    condition = contains(
      output.operational_alarm_arns,
      "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-api-5xx",
    )
    error_message = "Operational alarm outputs must contain the API 5xx alarm."
  }

  assert {
    condition = (
      output.api_4xx_alarm_arn
      == "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-api-4xx"
    )
    error_message = "API 4xx alarm ARN output is incorrect."
  }

  assert {
    condition = contains(
      output.operational_alarm_arns,
      "arn:aws:cloudwatch:us-east-1:123456789012:alarm:portfolio-test-dev-inquiry-api-4xx",
    )
    error_message = "Operational alarm outputs must contain the API 4xx alarm."
  }

}

run "http_api_custom_throttling" {
  command = plan

  variables {
    enable_inquiry             = true
    allowed_origin             = "https://portfolio.example"
    project_name               = "portfolio-test"
    environment                = "dev"
    owner                      = "2aron41"
    api_throttling_burst_limit = 1
    api_throttling_rate_limit  = 0.5
  }

  assert {
    condition = (
      aws_apigatewayv2_stage.inquiry[0]
      .default_route_settings[0]
      .throttling_burst_limit
      == 1
    )
    error_message = "HTTP API must honor the configured burst throttle."
  }

  assert {
    condition = (
      aws_apigatewayv2_stage.inquiry[0]
      .default_route_settings[0]
      .throttling_rate_limit
      == 0.5
    )
    error_message = "HTTP API must honor the configured rate throttle."
  }
}

run "reject_zero_api_throttling_burst_limit" {
  command = plan

  variables {
    api_throttling_burst_limit = 0
  }

  expect_failures = [
    var.api_throttling_burst_limit,
  ]
}

run "reject_fractional_api_throttling_burst_limit" {
  command = plan

  variables {
    api_throttling_burst_limit = 1.5
  }

  expect_failures = [
    var.api_throttling_burst_limit,
  ]
}

run "reject_zero_api_throttling_rate_limit" {
  command = plan

  variables {
    api_throttling_rate_limit = 0
  }

  expect_failures = [
    var.api_throttling_rate_limit,
  ]
}


run "inquiry_api_4xx_alarm_detects_sustained_client_errors" {
  command = plan

  override_resource {
    target = aws_apigatewayv2_api.inquiry[0]

    values = {
      id            = "mock-inquiry-api-id"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:mock-inquiry-api-id"
    }

    override_during = plan
  }

  variables {
    enable_inquiry            = true
    enable_operational_alarms = true
    project_name              = "portfolio-test"
    environment               = "dev"
    owner                     = "2aron41"
    allowed_origin            = "https://example.com"
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].alarm_name
      == "portfolio-test-dev-inquiry-api-4xx"
    )
    error_message = "API 4xx alarm name is incorrect."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].namespace
      == "AWS/ApiGateway"
    )
    error_message = "API 4xx alarm must use AWS/ApiGateway."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].metric_name
      == "4xx"
    )
    error_message = "API 4xx alarm must monitor 4xx."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].statistic
      == "Sum"
    )
    error_message = "API 4xx alarm must use Sum."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].period
      == 300
    )
    error_message = "API 4xx alarm must use a five-minute period."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].threshold
      == 20
    )
    error_message = "API 4xx alarm default threshold must be 20."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].evaluation_periods
      == 2
    )
    error_message = "API 4xx alarm must evaluate two periods."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].datapoints_to_alarm
      == 2
    )
    error_message = "API 4xx alarm must require two breaching datapoints."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0]
      .comparison_operator
      == "GreaterThanOrEqualToThreshold"
    )
    error_message = "API 4xx alarm comparison operator is incorrect."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].treat_missing_data
      == "notBreaching"
    )
    error_message = "API 4xx alarm must treat missing data as not breaching."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0]
      .dimensions["ApiId"]
      == "mock-inquiry-api-id"
    )
    error_message = "API 4xx alarm must target the inquiry HTTP API."
  }
}


run "inquiry_api_4xx_alarm_threshold_is_configurable" {
  command = plan

  override_resource {
    target = aws_apigatewayv2_api.inquiry[0]

    values = {
      id            = "mock-inquiry-api-id"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:mock-inquiry-api-id"
    }

    override_during = plan
  }

  variables {
    enable_inquiry            = true
    enable_operational_alarms = true
    api_4xx_alarm_threshold   = 30
    project_name              = "portfolio-test"
    environment               = "dev"
    owner                     = "2aron41"
    allowed_origin            = "https://example.com"
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].threshold
      == 30
    )
    error_message = "API 4xx alarm must honor the configured threshold."
  }
}


# Day 45 — Lambda version / alias recovery contract.
#
# These tests intentionally precede the module implementation.
# Phase A must create a published Lambda version and a `live` alias while
# preserving the existing unqualified API Gateway integration.

run "lambda_alias_absent_when_disabled" {
  command = plan

  assert {
    condition = (
      length(aws_lambda_alias.inquiry_live) == 0
    )
    error_message = "Lambda live alias must not exist while inquiry is disabled."
  }

  assert {
    condition = (
      length(aws_lambda_permission.inquiry_api_alias) == 0
    )
    error_message = "Alias-specific API Gateway permission must not exist while inquiry is disabled."
  }
}

run "lambda_version_and_live_alias_when_enabled" {
  command = plan

  override_resource {
    target          = aws_lambda_alias.inquiry_live[0]
    override_during = plan

    values = {
      invoke_arn = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:mock-inquiry:live/invocations"
    }
  }

  variables {
    enable_inquiry      = true
    enable_lambda_alias = true
    allowed_origin      = "https://portfolio.example"
    project_name        = "portfolio-test"
    environment         = "dev"
    owner               = "2aron41"
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].publish
      == true
    )
    error_message = "Enabling Lambda alias recovery must publish numbered Lambda versions."
  }

  assert {
    condition = (
      length(aws_lambda_alias.inquiry_live) == 1
    )
    error_message = "Exactly one live Lambda alias must be created."
  }

  assert {
    condition = (
      aws_lambda_alias.inquiry_live[0].name
      == "live"
    )
    error_message = "Production recovery alias must be named live."
  }

  assert {
    condition = (
      aws_lambda_alias.inquiry_live[0].function_name
      == aws_lambda_function.inquiry[0].function_name
    )
    error_message = "Live alias must target the inquiry Lambda function."
  }

  assert {
    condition = (
      aws_lambda_alias.inquiry_live[0].function_version
      == aws_lambda_function.inquiry[0].version
    )
    error_message = "Without a rollback override, live must follow the freshly published Lambda version."
  }

  # Phase A safety contract:
  # API Gateway must continue invoking the existing unqualified Lambda.
  assert {
    condition = (
      aws_apigatewayv2_integration.inquiry[0].integration_uri
      == aws_lambda_alias.inquiry_live[0].invoke_arn
    )
    error_message = "When Lambda alias recovery is enabled, API Gateway must route through the live alias invoke ARN."
  }
}

run "lambda_alias_rollback_version_override" {
  command = plan

  variables {
    enable_inquiry       = true
    enable_lambda_alias  = true
    lambda_alias_version = "7"

    allowed_origin = "https://portfolio.example"
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
  }

  assert {
    condition = (
      aws_lambda_alias.inquiry_live[0].function_version
      == "7"
    )
    error_message = "Explicit lambda_alias_version must pin live to the requested numbered version."
  }
}

run "lambda_alias_invoke_permission_when_enabled" {
  command = plan

  variables {
    enable_inquiry      = true
    enable_lambda_alias = true
    allowed_origin      = "https://portfolio.example"
    project_name        = "portfolio-test"
    environment         = "dev"
    owner               = "2aron41"
  }

  assert {
    condition = (
      length(aws_lambda_permission.inquiry_api_alias) == 1
    )
    error_message = "Exactly one alias-specific API Gateway invoke permission must exist."
  }

  assert {
    condition = (
      length(aws_lambda_permission.inquiry_api) == 0
    )
    error_message = "Base API Gateway invoke permission must be absent when traffic is routed through the live alias."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api_alias[0].principal
      == "apigateway.amazonaws.com"
    )
    error_message = "Only API Gateway should receive alias invoke permission."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api_alias[0].action
      == "lambda:InvokeFunction"
    )
    error_message = "Alias permission must allow only Lambda invocation."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api_alias[0].function_name
      == aws_lambda_function.inquiry[0].function_name
    )
    error_message = "Alias permission must target the inquiry Lambda."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api_alias[0].qualifier
      == aws_lambda_alias.inquiry_live[0].name
    )
    error_message = "Alias permission must be scoped specifically to the live alias."
  }

  assert {
    condition = (
      aws_lambda_permission.inquiry_api_alias[0].source_arn
      == "arn:aws:execute-api:us-east-1:123456789012:mockapi123/$default/POST/inquiries"
    )
    error_message = "Alias permission must remain scoped to default-stage POST /inquiries."
  }
}


run "lambda_alias_default_off_when_inquiry_enabled" {
  command = plan

  variables {
    enable_inquiry = true
    allowed_origin = "https://portfolio.example"
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
  }

  assert {
    condition = (
      aws_lambda_function.inquiry[0].publish
      == false
    )
    error_message = "Lambda version publication must remain disabled unless alias recovery is explicitly enabled."
  }

  assert {
    condition = (
      length(aws_lambda_alias.inquiry_live) == 0
    )
    error_message = "Live alias must remain absent when alias recovery is not explicitly enabled."
  }

  assert {
    condition = (
      length(aws_lambda_permission.inquiry_api_alias) == 0
    )
    error_message = "Alias-specific invoke permission must remain absent when alias recovery is disabled."
  }

  assert {
    condition = (
      length(aws_lambda_permission.inquiry_api) == 1
    )
    error_message = "Base API Gateway invoke permission must remain present when alias routing is disabled."
  }

  assert {
    condition = (
      aws_apigatewayv2_integration.inquiry[0].integration_uri
      == aws_lambda_function.inquiry[0].invoke_arn
    )
    error_message = "Default configuration must preserve the existing unqualified API Gateway integration."
  }
}

run "reject_invalid_lambda_alias_version" {
  command = plan

  variables {
    enable_inquiry       = true
    enable_lambda_alias  = true
    lambda_alias_version = "0"

    allowed_origin = "https://portfolio.example"
    project_name   = "portfolio-test"
    environment    = "dev"
    owner          = "2aron41"
  }

  expect_failures = [
    var.lambda_alias_version,
  ]
}
