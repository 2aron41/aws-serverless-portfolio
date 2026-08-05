resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = false

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.enable_encryption ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  cloudfront_origin_id = "${var.bucket_name}-s3-origin"
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.enable_cloudfront ? 1 : 0

  name                              = substr("${var.bucket_name}-oac", 0, 64)
  description                       = "Origin Access Control for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  count = var.enable_cloudfront ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static-site distribution for ${var.bucket_name}"
  default_root_object = var.default_root_object
  price_class         = var.cloudfront_price_class

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
    origin_id                = local.cloudfront_origin_id
  }

  default_cache_behavior {
    allowed_methods        = var.cloudfront_allowed_methods
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.cloudfront_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

data "aws_iam_policy_document" "cloudfront_s3_read" {
  count = var.enable_cloudfront ? 1 : 0

  statement {
    sid    = "AllowCloudFrontReadOnly"
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type = "Service"

      identifiers = [
        "cloudfront.amazonaws.com",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.this[0].arn,
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront" {
  count = var.enable_cloudfront ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.cloudfront_s3_read[0].json

  depends_on = [
    aws_s3_bucket_public_access_block.this,
  ]
}
