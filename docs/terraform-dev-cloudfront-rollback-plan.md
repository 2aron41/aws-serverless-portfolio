# Terraform Dev CloudFront Rollback Plan

## Purpose

Document how to safely remove the development CloudFront and Origin Access Control resources if needed.

## Current Dev Resources

- CloudFront distribution
- Origin Access Control
- S3 bucket policy
- Development S3 bucket

## Safe Rollback Method

1. Confirm the active Terraform directory is the development environment.
2. Verify the active AWS identity and account.
3. Back up the remote Terraform state.
4. Set `enable_cloudfront = false` only in the ignored development `terraform.tfvars`.
5. Run `terraform fmt -recursive` and `terraform validate`.
6. Run and save a Terraform plan.
7. Confirm the plan proposes removal only of the development:
   - CloudFront distribution
   - Origin Access Control
   - CloudFront S3 bucket policy
8. Confirm the plan does not replace or destroy the development S3 bucket.
9. Confirm the plan does not touch production, IAM, DNS, or unrelated resources.
10. Apply only the reviewed saved plan if cleanup is explicitly approved.
11. Run a final Terraform plan and confirm no changes remain.
12. Verify the development S3 bucket still has Block Public Access enabled.

## Stop Conditions

Stop if Terraform proposes:

- Destroying the development S3 bucket
- Replacing the development S3 bucket
- Touching production resources
- Changing IAM
- Changing DNS
- Making S3 public
- Modifying unrelated resources
- Applying a plan that was not reviewed and saved

## Decision

Do not destroy the development CloudFront resources today. Keep them temporarily for continued testing and production-migration preparation.
