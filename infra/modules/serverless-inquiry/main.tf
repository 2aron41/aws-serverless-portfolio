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
  integration_uri    = aws_lambda_function.inquiry[0].invoke_arn

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
    throttling_burst_limit = 2
    throttling_rate_limit  = 1
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
