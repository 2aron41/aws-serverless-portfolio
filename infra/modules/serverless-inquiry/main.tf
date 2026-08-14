locals {
  lambda_function_name = "${var.project_name}-${var.environment}-inquiry"
  inquiry_topic_name   = "${var.project_name}-${var.environment}-inquiries"

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

  reserved_concurrent_executions = 2

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
