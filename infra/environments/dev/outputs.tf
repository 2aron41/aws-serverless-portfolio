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
  description = "Name of the Terraform-managed dev S3 bucket."
  value       = module.static_site.bucket_name
}
