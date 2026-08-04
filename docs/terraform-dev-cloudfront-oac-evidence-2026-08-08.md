# Terraform Dev CloudFront/OAC Evidence — August 8, 2026

## Goal
Enable CloudFront, Origin Access Control (OAC), and the private S3 bucket policy in the development Terraform environment only.

## Pre-Change Safety
- AWS identity verified: Yes (`arn:aws:iam::510497448584:user/aaron-admin`)
- Remote state initialized: Yes (S3 backend with `use_lockfile = true`)
- State backup created: Yes (`/workspaces/terraform-state-backups/day-23-before-dev-cloudfront.json`)
- Pre-change plan: `No changes. Your infrastructure matches the configuration.`

## Dev Configuration Change
- `enable_cloudfront = true` is configured in the ignored development `terraform.tfvars` file.

## Terraform Plan
- Plan file: Not created during this verification session.
- Resources to add: Not observed.
- Resources to change: 0
- Resources to destroy: 0

## Expected Resources
- CloudFront distribution: Not present in Terraform state.
- Origin Access Control: Not present in Terraform state.
- S3 bucket policy: Not present in Terraform state.

## Stop Conditions Checked
- S3 replacement: No replacement proposed.
- Destroy actions: None.
- Public bucket access: S3 bucket remains private.
- Production resources: None changed.
- IAM changes: None observed.
- DNS changes: None observed.

## Apply Result
- No Terraform apply was performed during this verification session.

## Final Verification
- Final terraform plan: `No changes. Your infrastructure matches the configuration.`
- Terraform outputs:
  - `aws_region = us-east-1`
  - `environment = dev`
  - `project_name = aws-serverless-portfolio`
  - `dev_bucket_name = aws-serverless-portfolio-dev-2aron41-8ab73efa81e3bceff8c0a3d066`
- CloudFront domain: Not available.
- Dev S3 bucket still private: Yes.
- Production resources changed: No.

## Problems Encountered
- CloudFront resources were not present in the Terraform state.
- No `cloudfront_domain_name` output exists because no CloudFront distribution has been created.
- The saved Day 23 plan (`day-23-dev-cloudfront.tfplan`) was not available during verification.

## Fixes
- Verified the current Terraform state and outputs.
- Confirmed the remote backend and state backup.
- Updated this evidence document to match the actual Terraform state instead of expected results.

## Lessons Learned
- Evidence should only contain verified Terraform and AWS results.
- A `No changes` plan means the current configuration matches the deployed infrastructure.
- Terraform outputs only exist after resources and output blocks have been applied.
- CloudFront verification cannot occur until a CloudFront distribution is actually planned and applied.
