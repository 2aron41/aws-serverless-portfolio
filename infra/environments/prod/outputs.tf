output "project_name" {
  value = var.project_name
}

output "environment" {
  value = var.environment
}

output "aws_region" {
  value = var.aws_region
}

output "prod_bucket_name" {
  description = "Name of the production S3 bucket."
  value       = module.static_site.bucket_name
}

output "cloudfront_distribution_id" {
  description = "ID of the production CloudFront distribution."
  value       = module.static_site.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the production CloudFront distribution."
  value       = module.static_site.cloudfront_domain_name
}

output "cloudfront_oac_id" {
  description = "ID of the production CloudFront Origin Access Control."
  value       = module.static_site.origin_access_control_id
}

output "inquiry_enabled" {
  description = "Whether the production serverless inquiry workload is enabled."
  value       = module.serverless_inquiry.enabled
}

output "inquiry_api_endpoint" {
  description = "Production inquiry POST endpoint when enabled."
  value       = module.serverless_inquiry.api_endpoint
}

output "inquiry_lambda_function_name" {
  description = "Production inquiry Lambda function name when enabled."
  value       = module.serverless_inquiry.lambda_function_name
}

output "inquiry_sns_topic_arn" {
  description = "Production inquiry SNS topic ARN when enabled."
  value       = module.serverless_inquiry.sns_topic_arn
}


output "inquiry_operational_alarms_enabled" {
  description = "Whether production inquiry operational alarms are enabled."
  value       = var.enable_inquiry && var.enable_inquiry_operational_alarms
}


output "inquiry_operational_alarm_topic_arn" {
  description = "SNS topic ARN used by production inquiry operational alarms."
  value = (
    var.enable_inquiry && var.enable_inquiry_operational_alarms
    ? aws_sns_topic.inquiry_operations[0].arn
    : null
  )
}


output "inquiry_operational_alarm_arns" {
  description = "Production inquiry operational CloudWatch alarm ARNs."
  value       = module.serverless_inquiry.operational_alarm_arns
}
