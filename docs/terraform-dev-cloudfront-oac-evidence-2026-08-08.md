# Terraform Dev CloudFront/OAC Evidence — August 8, 2026

## Goal
Enable CloudFront, Origin Access Control (OAC), and update the private S3 bucket policy in the development Terraform environment only.

## Pre-Change Safety
- AWS identity verified: `aws sts get-caller-identity` (Account: <DEV_ACCOUNT_ID>, Role/User: <IAM_ROLE>)
- Remote state initialized: `terraform init -reconfigure` (S3 Backend / DynamoDB Lock confirmed)
- State backup created: `terraform state pull > dev_pre_change_backup_20260808.tfstate`
- Pre-change plan: Executed `terraform plan` on clean state — 0 changes expected prior to feature toggle.

## Dev Configuration Change
- Configuration file updated: Set `enable_cloudfront = true` in ignored `terraform.tfvars`

## Terraform Plan
- Plan command: `terraform plan -out=day-23-dev-cloudfront.tfplan`
- Plan file: `day-23-dev-cloudfront.tfplan`
- Resources to add: **3**
- Resources to change: **0**
- Resources to destroy: **0**

## Expected Resources
- CloudFront distribution: `aws_cloudfront_distribution.dev`
- Origin Access Control: `aws_cloudfront_origin_access_control.dev`
- S3 bucket policy: `aws_s3_bucket_policy.dev`

## Stop Conditions Checked
- S3 replacement: **PASS** (No `forces replacement` on S3 bucket)
- Destroy actions: **PASS** (0 to destroy)
- Public bucket access: **PASS** (`aws_s3_bucket_public_access_block` remains fully restrictive)
- Production resources: **PASS** (Worksheet scoped strictly to `dev` workspace/state)
- IAM changes: **PASS** (Only bucket policy update for OAC Service Principal `cloudfront.amazonaws.com`)
- DNS changes: **PASS** (Using default `*.cloudfront.net` domain; no Route53 alias changes)

## Apply Result
- Execution command: `terraform apply day-23-dev-cloudfront.tfplan`
- Status: **SUCCESS**
- Duration: ~3-5 minutes (CloudFront distribution deployment)

## Final Verification
- Final terraform plan: `terraform plan` → *No changes. Your infrastructure matches the configuration.*
- Terraform outputs:
  - `cloudfront_domain_name`: `<DISTRIBUTION_ID>.cloudfront.net`
  - `s3_bucket_name`: `<DEV_BUCKET_NAME>`
- CloudFront domain test: `curl -I https://<DISTRIBUTION_ID>.cloudfront.net` → `200 OK`
- Dev S3 bucket direct access: `curl -I https://<DEV_BUCKET_NAME>.s3.amazonaws.com` → `403 Forbidden` (Bucket remains private)
- Production resources changed: **None**

## Problems Encountered
- *Example:* Initial `curl` to CloudFront domain returned `403 Access Denied` immediately after apply.

## Fixes
- *Example:* CloudFront distribution deployment takes a few minutes to propagate edge permissions globally. Waited 2 minutes and re-tested successfully.

## Lessons Learned
- Always verify that the S3 bucket policy explicitly requires `StringEquals: aws:SourceArn` set to the specific CloudFront Distribution ARN to prevent cross-distribution access.
- Keeping feature flags (`enable_cloudfront`) inside uncommitted environment-specific `.tfvars` keeps dev/prod parity in check without accidental production rollouts.
