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
