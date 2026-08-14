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
