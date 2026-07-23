# Dev Bucket Cleanup Decision

## Resource

Terraform-managed development S3 bucket:

`aws-serverless-portfolio-dev-2aron41-8ab73efa81e3bceff8c0a3d066`

## Current Purpose

Terraform learning and safe development testing.

The bucket is currently being used to practice:

- Terraform state inspection
- Drift detection
- Resource imports and state recovery
- Future module development
- Safe cleanup planning

## Reasons to Keep Temporarily

- Practice Terraform state management
- Practice drift detection
- Practice future module development
- Preserve a safe non-production resource for upcoming Terraform exercises
- Avoid recreating a new learning resource before the next exercise

## Reasons to Destroy Later

- Avoid unused resources
- Avoid unnecessary cloud clutter
- Practice safe Terraform cleanup
- Confirm that Terraform can remove only the intended development resources
- Reduce the number of long-lived test resources in the AWS account

## Decision

Keep temporarily.

The bucket will remain available for the next Terraform learning exercise. It will not be used for production website hosting or production deployments.

Before destroying it, a saved Terraform plan must clearly show that only these development resources will be removed:

- `aws_s3_bucket.dev`
- `aws_s3_bucket_public_access_block.dev`
- `aws_s3_bucket_versioning.dev`

## Review Date

July 21, 2026.

The original review date has passed, so the cleanup decision should be reassessed during the next Terraform session.

## Safety Requirements

Before running `terraform destroy`:

1. Confirm the correct AWS identity and account.
2. Confirm the working directory is `infra/environments/dev`.
3. Inspect `terraform state list`.
4. Confirm no production resource is in state.
5. Run and save a destroy plan.
6. Verify the plan targets only the three intended development resources.
7. Check whether the bucket contains any objects or versions.
8. Do not proceed if any unexpected resource appears.
