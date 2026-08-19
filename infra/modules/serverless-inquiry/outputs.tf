output "enabled" {
  description = "Whether the inquiry workload is enabled."
  value       = var.enable_inquiry
}

output "api_endpoint" {
  description = "POST inquiry endpoint when the inquiry workload is enabled."
  value = (
    var.enable_inquiry
    ? "${aws_apigatewayv2_api.inquiry[0].api_endpoint}/inquiries"
    : null
  )
}

output "lambda_function_name" {
  description = "Inquiry Lambda function name when enabled."
  value = (
    var.enable_inquiry
    ? aws_lambda_function.inquiry[0].function_name
    : null
  )
}

output "sns_topic_arn" {
  description = "Inquiry SNS topic ARN when enabled."
  value = (
    var.enable_inquiry
    ? aws_sns_topic.inquiry[0].arn
    : null
  )
}


output "lambda_error_alarm_arn" {
  description = "ARN of the inquiry Lambda error alarm when operational alarms are enabled."
  value = (
    var.enable_inquiry && var.enable_operational_alarms
    ? aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].arn
    : null
  )
}


output "lambda_throttle_alarm_arn" {
  description = "ARN of the inquiry Lambda throttle alarm when operational alarms are enabled."
  value = (
    var.enable_inquiry && var.enable_operational_alarms
    ? aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].arn
    : null
  )
}


output "api_5xx_alarm_arn" {
  description = "ARN of the inquiry API Gateway 5xx alarm when operational alarms are enabled."
  value = (
    var.enable_inquiry && var.enable_operational_alarms
    ? aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].arn
    : null
  )
}


output "operational_alarm_arns" {
  description = "ARNs of all inquiry operational alarms when enabled."
  value = (
    var.enable_inquiry && var.enable_operational_alarms
    ? [
      aws_cloudwatch_metric_alarm.inquiry_lambda_errors[0].arn,
      aws_cloudwatch_metric_alarm.inquiry_lambda_throttles[0].arn,
      aws_cloudwatch_metric_alarm.inquiry_api_5xx[0].arn,
      aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].arn,
    ]
    : []
  )
}


output "api_4xx_alarm_arn" {
  description = "ARN of the inquiry API Gateway 4xx alarm when operational alarms are enabled."
  value = (
    var.enable_inquiry && var.enable_operational_alarms
    ? aws_cloudwatch_metric_alarm.inquiry_api_4xx[0].arn
    : null
  )
}
