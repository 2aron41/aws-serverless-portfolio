# Terraform Dev Apply Evidence — July 19, 2026

## Goal

Create a safe dev-only S3 bucket using Terraform without touching the live portfolio infrastructure.

## Resources Created

- Dev S3 bucket: Created successfully; generated bucket name intentionally redacted.
- Public access block: Created with all four settings enabled.
- Versioning: Enabled.
- Tags: `Project`, `Environment`, `ManagedBy`, `Owner`, and `Purpose`.
- Website hosting: Not configured.
- Public bucket policy: Not configured.

## Commands Run

- `terraform fmt -recursive`: Passed.
- `terraform validate`: Passed.
- `terraform plan -out=day11.tfplan`: Passed.
- `terraform apply day11.tfplan`: Passed.
- `terraform state list`: Confirmed three managed dev resources.
- `terraform plan` after apply: No changes.

## Plan Review

### What Terraform planned to create

- `aws_s3_bucket.dev`
- `aws_s3_bucket_public_access_block.dev`
- `aws_s3_bucket_versioning.dev`
- Plan total: 3 to add, 0 to change, 0 to destroy.

### What Terraform did not plan to touch

- Existing production S3 bucket
- Existing CloudFront distribution
- Existing Origin Access Control
- Existing GitHub Actions IAM role or policy
- Existing portfolio website files

## AWS Verification

- Dev bucket exists: Yes.
- Region: `us-east-1`.
- Public access blocked: Yes; all four settings are enabled.
- Versioning enabled: Yes.
- Required tags present: Yes.
- S3 website hosting configured: No.
- Production bucket changed: No; it was absent from the Terraform plan and state.
- Production CloudFront changed: No; it was absent from the Terraform plan and state.

## Problems Encountered

- The previous AWS CLI profile was unavailable in the current Codespace.
- An initial plan failed because Terraform could not find that profile.
- A text-based destruction check incorrectly matched the phrase `0 to destroy`.

## Fixes

- Created and verified the `day11-dev` AWS login profile.
- Deleted the failed plan and generated a new authenticated plan.
- Reviewed the actual plan summary and resource addresses before applying.

## Lessons Learned

- `terraform plan` previews changes, while `terraform apply` executes an approved plan.
- A saved plan allows Terraform to apply the exact actions that were reviewed.
- Terraform state is created after apply and must be protected.
- Post-apply planning helps confirm that configuration and live infrastructure match.
- Dev and production resources should remain separated.
