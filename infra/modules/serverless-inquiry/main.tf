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
