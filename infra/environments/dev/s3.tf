resource "aws_s3_bucket" "dev" {
  bucket_prefix = "${var.project_name}-${var.environment}-${var.github_username}-"
  force_destroy = false

  tags = merge(local.common_tags, {
    Purpose = "Terraform practice"
    Owner   = var.github_username
  })

  lifecycle {
    precondition {
      condition     = var.environment == "dev"
      error_message = "The Day 11 practice bucket may only be created in dev."
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket = aws_s3_bucket.dev.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "dev" {
  bucket = aws_s3_bucket.dev.id

  versioning_configuration {
    status = "Enabled"
  }
}
