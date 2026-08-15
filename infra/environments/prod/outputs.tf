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
