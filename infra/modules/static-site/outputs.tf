output "bucket_name" {
  description = "Name of the managed S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the managed S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the managed S3 bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID, if CloudFront is enabled."
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.this[0].id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name, if CloudFront is enabled."
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.this[0].domain_name : null
}

output "origin_access_control_id" {
  description = "CloudFront Origin Access Control ID, if CloudFront is enabled."
  value       = var.enable_cloudfront ? aws_cloudfront_origin_access_control.this[0].id : null
}
