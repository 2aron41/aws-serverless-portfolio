# Terraform Production Import Readiness Gate — August 5, 2026

## Purpose

Define the mandatory conditions that must be satisfied before the existing production portfolio resources are imported into Terraform.

This document does not authorize an import by itself.

## Current Decision

**Status: Not authorized for import today.**

Day 28 completes planning and readiness review only.

No production backend, state, import, plan, or apply is permitted today.

## Architecture Readiness

- Separate development environment exists: Yes
- Separate production environment skeleton exists: Yes
- Development and production configurations are separated: Yes
- Planned production remote-state key differs from development: Yes
- Active production backend exists: No
- Production environment initialized: No

## Module Readiness

- S3 bucket configuration represented: Yes
- S3 Block Public Access represented: Yes
- S3 versioning configurable: Yes
- S3 encryption configurable: Yes
- CloudFront enabled state configurable: Yes
- CloudFront allowed methods configurable: Yes
- CloudFront price class configurable: Yes
- CloudFront comment configurable: Yes
- CloudFront origin ID configurable: Yes
- OAC name configurable: Yes
- OAC description configurable: Yes
- Bucket-policy SourceArn condition operator configurable: Yes
- Production-compatible mocked test exists: Yes
- Terraform tests passing: 13 of 13

## Production-Matching Values

The future local production variables file must match the inventoried production configuration:

- Environment: `prod`
- Region: `us-east-1`
- Versioning: disabled before import
- Encryption: enabled with `AES256`
- CloudFront: enabled
- Default root object: `index.html`
- Price class: `PriceClass_All`
- Allowed methods: `GET`, `HEAD`
- CloudFront comment: explicitly empty
- Origin ID: reverified private production value
- OAC name: reverified private production value
- OAC description: `Created by CloudFront`
- SourceArn condition operator: `ArnLike`

## Tag Strategy

The existing production resources currently have no tags.

The module requires:

- `Project`
- `Environment`
- `ManagedBy`
- `Owner`
- `Purpose`

Decision:

- Keep the module's required tags.
- Treat proposed tag additions as expected post-import drift.
- Do not apply tag additions during the initial import session.
- Review and apply tags later through a separate saved plan.

## Mandatory Private Backups

Before import execution:

- Export CloudFront distribution configuration
- Export OAC configuration
- Export S3 bucket policy
- Record Block Public Access configuration
- Record S3 versioning configuration
- Record S3 encryption configuration
- Download `index.html`
- Download `styles.css`
- Record object sizes, metadata, and checksums
- Verify CloudFront returns HTTP 200
- Verify direct S3 access returns HTTP 403
- Back up the production Terraform state after backend initialization

## Identity and Directory Gates

Immediately before every import command:

- Verify the AWS identity
- Verify the AWS account
- Verify the current directory is `infra/environments/prod`
- Verify the production backend key
- Verify development state is not selected
- Verify the exact Terraform resource address
- Verify the exact AWS import identifier

## Planned Import Scope

Only these resources are currently approved for future import planning:

- S3 bucket
- S3 Block Public Access configuration
- S3 versioning configuration
- S3 encryption configuration
- CloudFront Origin Access Control
- CloudFront distribution
- S3 bucket policy

Website objects are not part of the Terraform import scope.

## Import Execution Rules

- Import one resource at a time.
- Inspect state after every import.
- Save a state backup after meaningful milestones.
- Do not run `terraform apply`.
- Do not run `terraform destroy`.
- Do not import resources into development state.
- Do not paste all imports into one command block.
- Stop on any uncertain identifier or address.

## Post-Import Plan Classification

Every proposed change must be classified as one of:

1. Expected provider normalization
2. Expected tag adoption
3. Safe but intentionally deferred improvement
4. Module mismatch requiring code changes
5. Destructive or unacceptable change

No plan may be applied until all changes are understood and approved.

## Immediate Stop Conditions

Stop if Terraform proposes:

- S3 bucket replacement or destruction
- CloudFront replacement or destruction
- OAC replacement or destruction
- Public S3 access
- Website object deletion or overwrite
- DNS or certificate changes
- IAM changes
- Development-state modification
- Duplicate production resources
- Unrelated infrastructure changes
- Any unreviewed apply

## Day 28 Readiness Result

Planning readiness: **Passed**

Execution authorization: **Not granted**

The project is ready for a future controlled production-import session after private backups, exact identifier reverification, backend activation review, and explicit approval.
