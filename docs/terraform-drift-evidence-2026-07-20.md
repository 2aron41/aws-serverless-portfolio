# Terraform Drift Evidence — July 20, 2026

## Goal

Practice detecting a safe manual change made outside Terraform without modifying production infrastructure.

## Resources in Scope

Only these Terraform-managed development resources were involved:

- `aws_s3_bucket.dev`
- `aws_s3_bucket_public_access_block.dev`
- `aws_s3_bucket_versioning.dev`

Development bucket:

`aws-serverless-portfolio-dev-2aron41-8ab73efa81e3bceff8c0a3d066`

## Manual Change Made

The following tag was manually added to the development S3 bucket through the AWS Console:

- Key: `TemporaryDrift`
- Value: `true`

No versioning, public-access, object, CloudFront, or production settings were changed.

## Terraform Plan Result

Terraform detected that the tag existed in AWS but was not declared in the Terraform configuration.

It proposed removing the unmanaged tag with an in-place update:

```text
"TemporaryDrift" = "true" -> null
```

The plan summary was:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

## Why This Is Drift

Terraform drift occurs when real infrastructure differs from the infrastructure declared in Terraform configuration.

The `TemporaryDrift` tag existed in AWS but not in `s3.tf`, so the real bucket and Terraform configuration did not match.

## Fix

The temporary tag was removed manually through the AWS Console.

Terraform was not applied because this exercise focused on detecting and manually correcting a safe console change.

## Final Plan Result

After removing the temporary tag, Terraform returned:

```text
No changes. Your infrastructure matches the configuration.
```

The state still contained only the three intended development resources.

## Lesson Learned

Manual changes to Terraform-managed infrastructure can create drift and make the real environment inconsistent with reviewed configuration.

Infrastructure changes should normally be made in Terraform code, reviewed with `terraform plan`, and applied through a controlled process.

Development resources are safer than production resources for practicing drift detection.

## Production Impact

Production resources changed: No.
