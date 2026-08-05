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

## Remaining Review Item

The production resources currently have no tags, while the module requires standard tags. Tag adoption must be reviewed separately before any production apply.

## Safety Rules

Do not run the following in this directory yet:

- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform import`
- `terraform destroy`

Do not create a real production backend or production state until the module configuration has been reviewed and production import planning is complete.

## Next Steps

1. Add tests for the production-matching CloudFront and OAC values.
2. Review the remaining tag difference.
3. Reverify exact production identifiers before import.
4. Create the production backend only after the configuration is ready.
5. Review the import sequence before executing any import.
