# Static Site Terraform Module

## Purpose

Reusable Terraform module for managing the S3 foundation of a private static website environment.

The module currently manages the same development S3 infrastructure that was originally declared directly in `infra/environments/dev`.

## Inputs

### `bucket_name`

- Description: Exact name of the S3 bucket
- Type: `string`
- Required: Yes

### `enable_versioning`

- Description: Whether S3 versioning is enabled
- Type: `bool`
- Default: `true`

### `tags`

- Description: Tags applied to the S3 bucket
- Type: `map(string)`
- Default: `{}`

## Resources Managed

- `aws_s3_bucket.this`
- `aws_s3_bucket_public_access_block.this`
- `aws_s3_bucket_versioning.this`

The S3 bucket uses `force_destroy = false`.

The public-access-block resource enables all four protections:

- Block public ACLs
- Ignore public ACLs
- Block public bucket policies
- Restrict public buckets

## Outputs

- `bucket_name`
- `bucket_arn`
- `bucket_regional_domain_name`

## Current Dev Usage

The dev environment calls the module with the existing development bucket name and preserves all five existing tags:

- `Project`
- `Environment`
- `ManagedBy`
- `Purpose`
- `Owner`

## Refactor Safety

The existing dev resources were moved into this module using Terraform `moved` blocks.

The reviewed plan reported:

```text
Plan: 0 to add, 0 to change, 0 to destroy.
```

After applying the saved move-only plan, the final Terraform plan returned:

```text
No changes. Your infrastructure matches the configuration.
```

## Not Included

- Website file uploads
- CloudFront distribution
- CloudFront Origin Access Control
- CloudFront invalidations
- IAM deployment permissions
- Application deployment
- Production infrastructure

Website files should remain deployed through GitHub Actions because application content changes more frequently than infrastructure.

## Future Work

- Test additional module inputs in dev
- Add CloudFront and OAC only in a separately reviewed milestone
- Define production migration and rollback procedures
- Keep production resources unchanged until the module is fully validated

## Example Usage

```hcl
module "static_site" {
  source = "../../modules/static-site"

  bucket_name       = "example-dev-bucket-name"
  environment       = "dev"
  enable_versioning = true

  tags = {
    Project     = "aws-serverless-portfolio"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "Aaron"
    Purpose     = "terraform-practice"
  }
}
```

## Managed Resources

- S3 bucket
- S3 public access block
- S3 versioning

## Not Yet Managed

- CloudFront distribution
- Origin Access Control
- IAM deployment role
- Production resources
- Website uploads
- CloudFront invalidations

## Input Validation

The module validates:

- Bucket names are between 3 and 63 characters
- Bucket names use supported lowercase characters
- The environment is either `dev` or `prod`
- Required tags are present and non-empty:
  - `Project`
  - `Environment`
  - `ManagedBy`
  - `Owner`
  - `Purpose`
