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

## Known Module Mismatch

The current static-site module hardcodes CloudFront allowed methods as:

- `GET`
- `HEAD`
- `OPTIONS`

The existing production distribution allows only:

- `GET`
- `HEAD`

This mismatch must be resolved before production import.

## Safety Rules

Do not run the following in this directory yet:

- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform import`
- `terraform destroy`

Do not create a real production backend or production state until the module configuration has been reviewed and production import planning is complete.

## Next Steps

1. Make CloudFront allowed methods configurable.
2. Add tests for production-compatible allowed methods.
3. Review all remaining differences between production and the module.
4. Create the production backend only after the configuration is ready.
5. Prepare exact import addresses and IDs.
6. Review the import sequence before executing any import.
