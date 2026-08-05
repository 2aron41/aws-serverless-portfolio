# Production Terraform Environment

## Purpose

Prepare a separate Terraform environment for the existing production portfolio resources without importing or modifying them yet.

## Current Status

Planning only.

This directory does not contain:

- A production backend configuration
- A real `terraform.tfvars`
- Imported production resources
- Production Terraform state

## Current Production Configuration

The Day 25 inventory found:

- Private production S3 bucket
- S3 Block Public Access enabled
- SSE-S3 `AES256` encryption
- Versioning disabled
- CloudFront enabled
- Origin Access Control enabled
- Default root object `index.html`
- CloudFront price class `PriceClass_All`
- Allowed methods `GET` and `HEAD`
- Default CloudFront certificate
- No custom aliases
- No Route 53 hosted zone
- No ACM certificate

## Production-Matching Controls

The module now supports production-specific values for:

- CloudFront allowed methods
- CloudFront price class
- CloudFront comment
- CloudFront origin ID
- OAC name
- OAC description
- S3 bucket-policy SourceArn condition operator

Development can retain its existing defaults while production can model the current live configuration more closely.

## Tag Adoption Decision

The existing production resources currently have no tags, while the module requires standard governance tags.

The module tag requirements will remain enabled.

After import, Terraform may propose adding the following tags:

- `Project`
- `Environment`
- `ManagedBy`
- `Owner`
- `Purpose`

Tag additions must be reviewed as a separate, intentional in-place improvement. They must not be applied during the initial production import session.

## Safety Rules

Do not run the following in this directory yet:

- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform import`
- `terraform destroy`

Do not create a real production backend or production state until the module configuration has been reviewed and production import planning is complete.

## Next Steps

1. Complete the production import-readiness gate.
2. Reverify exact production identifiers immediately before import.
3. Back up production configuration, content, and state.
4. Activate and review the isolated production backend.
5. Import and verify one resource at a time.
6. Do not apply post-import drift during the import session.
