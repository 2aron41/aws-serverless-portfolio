moved {
  from = aws_s3_bucket.dev
  to   = module.static_site.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_public_access_block.dev
  to   = module.static_site.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_versioning.dev
  to   = module.static_site.aws_s3_bucket_versioning.this
}
