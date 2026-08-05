# Terraform Production Import Plan — August 5, 2026

## Purpose

Prepare the resource addresses, import identifiers, ordering, safety controls, and review process for adopting the existing production portfolio infrastructure into a separate Terraform state.

This document is planning only.

No production backend was initialized, no production state was created, and no resources were imported or modified during Day 26.

## Current Production Resources

The Day 25 inventory identified:

- Existing production S3 bucket
- Existing S3 Block Public Access configuration
- Existing S3 versioning configuration
- Existing S3 encryption configuration
- Existing CloudFront Origin Access Control
- Existing CloudFront distribution
- Existing S3 bucket policy

Production contains two website objects:

- `index.html`
- `styles.css`

The website objects are not currently represented as Terraform resources and must not be deleted or overwritten during infrastructure adoption.

## Production Environment Location

`infra/environments/prod`

The production environment is separate from:

`infra/environments/dev`

## State Isolation

Production must use a different remote-state key from development.

Development key:

`aws-serverless-portfolio/dev/terraform.tfstate`

Planned production key:

`aws-serverless-portfolio/prod/terraform.tfstate`

The production backend remains disabled during Day 26. A template exists at:

`infra/environments/prod/backend.tf.example`

It must not be renamed or initialized until import execution is approved.

## Production-Compatible Module Settings

The production environment currently models:

- `environment = "prod"`
- Versioning disabled
- Explicit SSE-S3 encryption enabled
- CloudFront enabled
- Default root object `index.html`
- CloudFront price class `PriceClass_All`
- Allowed methods `GET` and `HEAD`

CloudFront allowed methods were made configurable so the module can represent the existing production distribution without automatically adding `OPTIONS`.

## Remaining Expected Differences

Day 27 added production-matching controls for:

- CloudFront comment
- CloudFront origin ID
- OAC name
- OAC description
- S3 bucket-policy SourceArn condition operator

These values can now be configured to match the existing production resources before import.

Remaining post-import differences may still include:

- Terraform-required tags that do not exist on current production resources
- Provider defaults or normalized CloudFront attributes
- S3 versioning behavior for a bucket that has never had versioning enabled
- Other attributes revealed only after state import and refresh

Every difference must be reviewed before any production apply.

## Planned Terraform Resource Addresses

The production module is expected to manage:

- `module.static_site.aws_s3_bucket.this`
- `module.static_site.aws_s3_bucket_public_access_block.this`
- `module.static_site.aws_s3_bucket_versioning.this`
- `module.static_site.aws_s3_bucket_server_side_encryption_configuration.this[0]`
- `module.static_site.aws_cloudfront_origin_access_control.this[0]`
- `module.static_site.aws_cloudfront_distribution.this[0]`
- `module.static_site.aws_s3_bucket_policy.cloudfront[0]`

The following data source is calculated and is not imported:

- `module.static_site.data.aws_iam_policy_document.cloudfront_s3_read[0]`

## Planned Import Identifier Types

| Terraform address | Import identifier type |
|---|---|
| `module.static_site.aws_s3_bucket.this` | Existing production bucket name |
| `module.static_site.aws_s3_bucket_public_access_block.this` | Existing production bucket name |
| `module.static_site.aws_s3_bucket_versioning.this` | Existing production bucket name |
| `module.static_site.aws_s3_bucket_server_side_encryption_configuration.this[0]` | Existing production bucket name |
| `module.static_site.aws_cloudfront_origin_access_control.this[0]` | Existing production OAC ID |
| `module.static_site.aws_cloudfront_distribution.this[0]` | Existing production distribution ID |
| `module.static_site.aws_s3_bucket_policy.cloudfront[0]` | Existing production bucket name |

Exact account and resource identifiers remain in private terminal evidence and should be reverified immediately before import.

## Proposed Import Order

1. S3 bucket
2. S3 Block Public Access configuration
3. S3 versioning configuration
4. S3 encryption configuration
5. CloudFront Origin Access Control
6. CloudFront distribution
7. S3 bucket policy

The order follows the main resource relationships represented in the module, but it must be reviewed again before execution.

## Future Command Pattern

Each resource should be imported individually.

After each import, verify it with:

- `terraform state list`
- `terraform state show <resource-address>`

Do not paste all production import commands into one large command block. Import and verify one resource at a time.

## Mandatory Pre-Import Backups

Before any import:

1. Verify the AWS identity.
2. Verify the working directory is `infra/environments/prod`.
3. Verify the production backend key differs from dev.
4. Back up any existing production Terraform state.
5. Export the production CloudFront distribution configuration.
6. Export the production OAC configuration.
7. Export the production bucket policy.
8. Record S3 Block Public Access settings.
9. Record S3 versioning and encryption settings.
10. Back up `index.html` and `styles.css`.
11. Record object metadata and checksums.
12. Confirm CloudFront returns `HTTP 200`.
13. Confirm direct S3 access returns `HTTP 403`.

## Import Safety Gates

Do not begin imports unless:

- The production configuration has been reviewed.
- A real production `terraform.tfvars` exists locally and is ignored by Git.
- The production backend key is unique and reviewed.
- The remote-state bucket is healthy and versioned.
- AWS authentication is valid.
- Development state remains unchanged.
- Production resource identifiers are reverified.
- Production content is backed up.
- The exact import sequence is reviewed.
- A rollback procedure is documented.

## Post-Import Review

After all planned imports:

1. Run `terraform state list`.
2. Confirm each expected resource appears exactly once.
3. Confirm no production resource appears in dev state.
4. Run `terraform plan -refresh-only`.
5. Review all refresh-only findings.
6. Run a normal saved Terraform plan.
7. Inspect every proposed change.
8. Classify each change as:
   - Expected normalization
   - Safe in-place update
   - Requires module adjustment
   - Destructive or unacceptable
9. Do not apply the plan.

The first target after import is an accurate and non-destructive understanding of drift, not necessarily an immediate no-change plan.

## Stop Conditions

Stop immediately if:

- The backend key points to development state.
- Terraform proposes creating duplicate production resources.
- Terraform proposes replacing or destroying the S3 bucket.
- Terraform proposes replacing or destroying the CloudFront distribution.
- Terraform proposes replacing or destroying the OAC.
- Website objects are at risk.
- The bucket could become public.
- DNS, certificates, IAM, or unrelated resources appear.
- A resource identifier is uncertain.
- A resource is imported into the wrong address.
- State cannot be backed up.
- AWS authentication changes unexpectedly.
- The plan has not been saved and reviewed.

## Rollback Concept

Terraform import changes state bindings; it does not directly change the live AWS resource.

If a resource is imported at the wrong address, the normal corrective action is to remove only that state binding using a reviewed `terraform state rm` command.

Removing a resource from Terraform state does not delete the live AWS resource, but every state operation must still be backed up and reviewed.

Do not use `terraform destroy` as an import rollback method.

## Day 26 Decision

The production environment skeleton and import plan are ready for review.

Do not initialize the production backend, create production state, import resources, or run a production plan today.


## Day 27 Drift-Reduction Update

The module now supports production-specific configuration for:

- CloudFront allowed methods
- CloudFront price class
- CloudFront comment, including an explicitly empty comment
- CloudFront origin ID
- OAC name
- OAC description
- S3 bucket-policy SourceArn condition operator

Terraform tests verify both the module defaults and production-compatible values.

The test suite now contains 13 passing tests.

The production tag strategy is now decided. Required module tags will remain enabled.

Because existing production resources have no tags, the first post-import plan may propose adding standard tags. Tag additions must be classified as a separate intentional improvement and must not be applied during the initial import session.

