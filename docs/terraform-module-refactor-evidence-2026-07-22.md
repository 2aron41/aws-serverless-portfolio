# Terraform Module Refactor Evidence — July 22, 2026

## Goal

Move the dev S3 resources into a reusable Terraform module without recreating, replacing, or destroying infrastructure.

## Pre-refactor State

Before the refactor, Terraform tracked:

- `aws_s3_bucket.dev`
- `aws_s3_bucket_public_access_block.dev`
- `aws_s3_bucket_versioning.dev`

The pre-refactor plan returned:

```text
No changes. Your infrastructure matches the configuration.
```

A protected remote-state backup was created outside Git at:

`/workspaces/terraform-state-backups/day-14-before-module-refactor.json`

## Module Created

The module was completed in `infra/modules/static-site/` with:

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `README.md`

The module manages:

- S3 bucket
- S3 public access block
- S3 versioning
- Existing S3 tags

CloudFront, OAC, IAM, website uploads, and production resources were not added.

## Moved Blocks Added

The following state-address mappings were added:

```text
aws_s3_bucket.dev
  -> module.static_site.aws_s3_bucket.this

aws_s3_bucket_public_access_block.dev
  -> module.static_site.aws_s3_bucket_public_access_block.this

aws_s3_bucket_versioning.dev
  -> module.static_site.aws_s3_bucket_versioning.this
```

## Plan Result

The reviewed saved plan showed only three resource-address moves:

```text
Plan: 0 to add, 0 to change, 0 to destroy.
```

The plan contained no replacements, destroys, new buckets, CloudFront resources, IAM resources, or production changes.

## Apply Result

The exact reviewed saved plan was applied.

Terraform updated the resource addresses in state without changing the real AWS infrastructure.

## Final State Addresses

- `module.static_site.aws_s3_bucket.this`
- `module.static_site.aws_s3_bucket_public_access_block.this`
- `module.static_site.aws_s3_bucket_versioning.this`

## Final Terraform Plan

```text
No changes. Your infrastructure matches the configuration.
```

## AWS Verification

- Original dev bucket still exists: Yes
- Original bucket name unchanged: Yes
- Five existing tags preserved: Yes
- All four public-access protections enabled: Yes
- S3 versioning enabled: Yes

## Production Resources Changed

No.

## Problems Encountered

- The module initially contained only planning documentation.
- The existing configuration used five tags, so passing only the common tags would have caused an unintended tag change.
- The existing bucket used a generated name, but the module required the exact current bucket name to avoid replacement.
- Local `terraform.tfvars` needed to remain ignored by Git.

## Fixes

- Inspected the exact state addresses and existing Terraform source before editing.
- Passed all five existing tags into the module.
- Used the exact existing dev bucket name through ignored `terraform.tfvars`.
- Added three precise `moved` blocks.
- Generated and reviewed a saved move-only plan before applying it.

## Lessons Learned

- Modules improve reuse but refactors must preserve resource identity.
- `moved` blocks prevent Terraform from interpreting address changes as replacement.
- A safe refactor plan should show zero infrastructure additions, changes, and destroys.
- State backups and a clean baseline plan are required before restructuring Terraform code.
- Development infrastructure should be modularized and validated before production resources.
