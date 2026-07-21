output "project_name" {
  value = var.project_name
}

output "environment" {
  value = var.environment
}

output "aws_region" {
  value = var.aws_region
}

output "dev_bucket_name" {
  description = "Generated name of the Terraform-managed dev S3 bucket."
  value       = aws_s3_bucket.dev.id
}
