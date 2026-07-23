# Terraform Remote State Setup — July 21, 2026

## Goal

Store Terraform development state remotely in a dedicated S3 backend instead of relying on temporary local Codespace storage.

## Backend Bucket

- Purpose: Store Terraform state and native S3 lock files
- Bucket: `cloud-ai-roadmap-terraform-state-510497448584-us-east-1`
- Region: `us-east-1`
- Public access: All four Block Public Access settings enabled
- Versioning: Enabled
- Encryption: SSE-S3 using `AES256`
- Management method: Manual bootstrap
- Tags:
  - `Project = cloud-ai-roadmap`
  - `Purpose = terraform-state`
  - `Environment = shared`
  - `ManagedBy = manual-bootstrap`

## Why This Bucket Is Separate

The state bucket stores Terraform state and lock files. It is not application infrastructure, a website bucket, or the Terraform-managed dev bucket.

Keeping state storage separate prevents the backend from depending on the same Terraform configuration whose state it stores.

## Safety Decisions

- State bucket is private.
- Versioning is enabled.
- Public access is blocked.
- Server-side encryption is enabled.
- Native S3 state locking is enabled with `use_lockfile = true`.
- No credentials are stored in `backend.tf`.
- No state or backup files are committed to GitHub.

## Backend Configuration

The dev environment uses:

```hcl
terraform {
  backend "s3" {
    bucket       = "cloud-ai-roadmap-terraform-state-510497448584-us-east-1"
    key          = "aws-serverless-portfolio/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

## Migration Evidence

### Commands Run

- `terraform state list`: Confirmed three dev-only resources before migration.
- `terraform plan`: Returned `No changes` before migration.
- `terraform state pull`: Created a protected pre-migration JSON backup outside Git.
- `terraform init -migrate-state`: Copied the existing local state to the S3 backend.
- `terraform state list`: Confirmed the same three resources after migration.
- `terraform plan`: Returned `No changes` after migration.

### Final Result

Final Terraform plan:

```text
No changes. Your infrastructure matches the configuration.
```

The remote state continues to track:

- `aws_s3_bucket.dev`
- `aws_s3_bucket_public_access_block.dev`
- `aws_s3_bucket_versioning.dev`

### AWS Verification

- State object exists in S3: Yes
- State key: `aws-serverless-portfolio/dev/terraform.tfstate`
- State object encryption: `AES256`
- Backend bucket public access blocked: Yes
- Backend bucket versioning enabled: Yes
- Historical `.tflock` versions observed: Yes
- Active lock object after commands completed: No
- Production resources changed: No

## Local-State Cleanup

- Pre-migration backup: `/workspaces/terraform-state-backups/day-13-dev-state-before-remote.json`
- Backup checksum: `9c23a946a0bde294a01bee681c43c8c1ada262200cb457452ec17148672f7003`
- Legacy local state archive: `/workspaces/terraform-state-backups/day-13-legacy-local-state/`
- Root-level state files were removed from the Terraform working directory after remote verification.
- `.terraform/terraform.tfstate` was retained because it stores backend metadata.

## Problems Encountered

- The previous local state had already demonstrated that Codespace-local storage could be lost.
- A root-level `terraform.tfstate` remained after migration but was empty.
- The legacy `terraform.tfstate.backup` contained the earlier three-resource local state.
- Long terminal pastes occasionally became corrupted.

## Fixes

- Created and validated a protected state backup before migration.
- Verified the backend bucket protections before configuring Terraform.
- Migrated using `terraform init -migrate-state`.
- Confirmed the remote state object, state resources, outputs, and clean plan.
- Archived the legacy local files outside both Git repositories.

## Lessons Learned

- Remote state removes dependency on one temporary Codespace.
- Backend storage should be created separately before migration.
- State must be backed up and inspected before changing backends.
- Versioning provides recovery history for state and lock objects.
- State locking protects against simultaneous state-writing operations.
- Successful migration means the same resources remain tracked and the final plan shows no changes.
