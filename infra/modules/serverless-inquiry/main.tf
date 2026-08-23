locals {
  lambda_function_name = "${var.project_name}-${var.environment}-inquiry"
  inquiry_topic_name   = "${var.project_name}-${var.environment}-inquiries"

  api_access_log_format = jsonencode({
    requestId          = "$context.requestId"
    requestTimeEpoch   = "$context.requestTimeEpoch"
    httpMethod         = "$context.httpMethod"
    routeKey           = "$context.routeKey"
    status             = "$context.status"
    responseLength     = "$context.responseLength"
    integrationLatency = "$context.integrationLatency"
    responseLatency    = "$context.responseLatency"
    integrationStatus  = "$context.integrationStatus"
  })

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Purpose     = "Portfolio inquiry service"
  }
}

resource "aws_sns_topic" "inquiry" {
  count = var.enable_inquiry ? 1 : 0

  name = local.inquiry_topic_name

  tags = local.common_tags
}


resource "aws_iam_role" "inquiry_lambda" {
  count = var.enable_inquiry ? 1 : 0

  name = "${local.lambda_function_name}-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"

        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "inquiry_lambda" {
  count = var.enable_inquiry ? 1 : 0

  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_iam_role_policy" "inquiry_lambda" {
  count = var.enable_inquiry ? 1 : 0

  name = "${local.lambda_function_name}-permissions"
  role = aws_iam_role.inquiry_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid      = "PublishInquiry"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.inquiry[0].arn
      },
      {
        Sid    = "WriteFunctionLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]

        # Terraform creates the log group, so Lambda does not
        # require logs:CreateLogGroup.
        Resource = "${aws_cloudwatch_log_group.inquiry_lambda[0].arn}:*"
      },
    ]
  })
}

data "archive_file" "inquiry_lambda" {
  count = var.enable_inquiry ? 1 : 0

  type        = "zip"
  output_path = "${path.root}/.terraform/${local.lambda_function_name}.zip"

  source {
    content = file(
      "${path.module}/../../../lambda_src/inquiry_handler.py"
    )
    filename = "inquiry_handler.py"
  }
}

resource "aws_lambda_function" "inquiry" {
  count = var.enable_inquiry ? 1 : 0

  function_name = local.lambda_function_name
  description   = "Processes validated portfolio inquiries."

  role    = aws_iam_role.inquiry_lambda[0].arn
  handler = "inquiry_handler.lambda_handler"
  runtime = "python3.12"

  architectures = [
    "x86_64",
  ]

  filename         = data.archive_file.inquiry_lambda[0].output_path
  source_code_hash = data.archive_file.inquiry_lambda[0].output_base64sha256

  publish = var.enable_lambda_alias

  memory_size = 128
  timeout     = 5

  reserved_concurrent_executions = -1

  environment {
    variables = {
      INQUIRY_TOPIC_ARN = aws_sns_topic.inquiry[0].arn
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.inquiry_lambda,
    aws_iam_role_policy.inquiry_lambda,
  ]
}

resource "aws_lambda_alias" "inquiry_live" {
  count = (
    var.enable_inquiry &&
    var.enable_lambda_alias
    ? 1
    : 0
  )

  name        = "live"
  description = "Stable recovery alias for the inquiry Lambda."

  function_name = aws_lambda_function.inquiry[0].function_name

  function_version = (
    var.lambda_alias_version != null
    ? var.lambda_alias_version
    : aws_lambda_function.inquiry[0].version
  )
}

resource "aws_apigatewayv2_api" "inquiry" {
  count = var.enable_inquiry ? 1 : 0

  name          = "${local.lambda_function_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = [
      "content-type",
    ]

    allow_methods = [
      "POST",
    ]

    allow_origins = [
      var.allowed_origin,
    ]

    max_age = 300
  }

  lifecycle {
    precondition {
      condition     = var.allowed_origin != ""
      error_message = "allowed_origin must be configured before enabling the inquiry API."
    }
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "inquiry" {
  count = var.enable_inquiry ? 1 : 0

  api_id = aws_apigatewayv2_api.inquiry[0].id

  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri = (
    var.enable_lambda_alias
    ? aws_lambda_alias.inquiry_live[0].invoke_arn
    : aws_lambda_function.inquiry[0].invoke_arn
  )

  payload_format_version = "2.0"
  timeout_milliseconds   = 5000
}

resource "aws_apigatewayv2_route" "inquiry" {
  count = var.enable_inquiry ? 1 : 0

  api_id = aws_apigatewayv2_api.inquiry[0].id

  route_key          = "POST /inquiries"
  authorization_type = "NONE"

  target = "integrations/${aws_apigatewayv2_integration.inquiry[0].id}"
}

resource "aws_cloudwatch_log_group" "inquiry_api_access" {
  count = var.enable_inquiry ? 1 : 0

  name              = "/aws/apigateway/${local.lambda_function_name}-access"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_apigatewayv2_stage" "inquiry" {
  count = var.enable_inquiry ? 1 : 0

  api_id = aws_apigatewayv2_api.inquiry[0].id

  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = var.api_throttling_burst_limit
    throttling_rate_limit  = var.api_throttling_rate_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.inquiry_api_access[0].arn
    format          = local.api_access_log_format
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "inquiry_api" {
  count = var.enable_inquiry ? 1 : 0

  statement_id  = "AllowInquiryApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inquiry[0].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.inquiry[0].execution_arn}/$default/POST/inquiries"
}

resource "aws_lambda_permission" "inquiry_api_alias" {
  count = (
    var.enable_inquiry &&
    var.enable_lambda_alias
    ? 1
    : 0
  )

  statement_id  = "AllowInquiryApiGatewayInvokeLiveAlias"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inquiry[0].function_name
  qualifier     = aws_lambda_alias.inquiry_live[0].name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.inquiry[0].execution_arn}/$default/POST/inquiries"
}


resource "aws_cloudwatch_metric_alarm" "inquiry_lambda_errors" {
  count = var.enable_inquiry && var.enable_operational_alarms ? 1 : 0

  alarm_name        = "${var.project_name}-${var.environment}-inquiry-lambda-errors"
  alarm_description = "Inquiry Lambda reported one or more execution errors."

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Sum"
  period      = 300

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  alarm_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  ok_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  dimensions = {
    FunctionName = aws_lambda_function.inquiry[0].function_name
  }

  tags = local.common_tags
}


resource "aws_cloudwatch_metric_alarm" "inquiry_lambda_throttles" {
  count = var.enable_inquiry && var.enable_operational_alarms ? 1 : 0

  alarm_name        = "${var.project_name}-${var.environment}-inquiry-lambda-throttles"
  alarm_description = "Inquiry Lambda reported one or more throttled invocations."

  namespace   = "AWS/Lambda"
  metric_name = "Throttles"
  statistic   = "Sum"
  period      = 300

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  alarm_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  ok_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  dimensions = {
    FunctionName = aws_lambda_function.inquiry[0].function_name
  }

  tags = local.common_tags
}


resource "aws_cloudwatch_metric_alarm" "inquiry_api_5xx" {
  count = var.enable_inquiry && var.enable_operational_alarms ? 1 : 0

  alarm_name        = "${var.project_name}-${var.environment}-inquiry-api-5xx"
  alarm_description = "Inquiry API Gateway reported one or more server errors."

  namespace   = "AWS/ApiGateway"
  metric_name = "5xx"
  statistic   = "Sum"
  period      = 300

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  alarm_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  ok_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  dimensions = {
    ApiId = aws_apigatewayv2_api.inquiry[0].id
  }

  tags = local.common_tags
}


resource "aws_cloudwatch_metric_alarm" "inquiry_api_4xx" {
  count = var.enable_inquiry && var.enable_operational_alarms ? 1 : 0

  alarm_name        = "${var.project_name}-${var.environment}-inquiry-api-4xx"
  alarm_description = "Inquiry API Gateway reported sustained abnormal client-error traffic."

  namespace   = "AWS/ApiGateway"
  metric_name = "4xx"
  statistic   = "Sum"
  period      = 300

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.api_4xx_alarm_threshold
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  treat_missing_data = "notBreaching"

  alarm_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  ok_actions = var.operational_alarm_topic_arn != null ? [
    var.operational_alarm_topic_arn,
  ] : []

  dimensions = {
    ApiId = aws_apigatewayv2_api.inquiry[0].id
  }

  tags = local.common_tags
}
