# Terraform Production Resource Inventory — August 5, 2026

## Purpose

Document the existing manually created production portfolio resources before creating a production Terraform environment or attempting any imports.

No production resources were imported, modified, replaced, or deleted during this inventory.

## AWS Identity

- AWS account verified: Yes
- IAM administrative identity verified: Yes
- Region used for S3 resources: `us-east-1`

Sensitive account and identity values are intentionally omitted from this public document.

## Production S3 Bucket

- Purpose: Hosts the production portfolio website files
- Region: `us-east-1`
- Managed by Terraform: No
- Present in development Terraform state: No
- Object count: 2
- Total object size: 6,534 bytes
- Storage class: `STANDARD`
- Versioning enabled: No
- Default encryption: `AES256` using SSE-S3
- S3 website hosting enabled: No
- Bucket tags: None
- Bucket policy public status: `IsPublic = false`

### Production Objects

- `index.html`
- `styles.css`

## Production S3 Privacy

All four bucket-level S3 Block Public Access protections are enabled:

- `BlockPublicAcls = true`
- `IgnorePublicAcls = true`
- `BlockPublicPolicy = true`
- `RestrictPublicBuckets = true`

Direct access to the production S3 object returned `HTTP/1.1 403 Forbidden`.

The production bucket remains private.

## Production CloudFront Distribution

- Status: `Deployed`
- Enabled: Yes
- Default root object: `index.html`
- Origin: Production S3 regional endpoint
- Origin Access Control configured: Yes
- Legacy Origin Access Identity configured: No
- Viewer protocol policy: `redirect-to-https`
- Allowed methods: `GET`, `HEAD`
- Cached methods: `GET`, `HEAD`
- Price class: `PriceClass_All`
- IPv6 enabled: Yes
- HTTP version: `http2`
- CloudFront default certificate: Yes
- Custom aliases: None
- ACM certificate: None
- Minimum protocol version reported: `TLSv1`

The production CloudFront domain successfully returned `HTTP/2 200` with `Content-Type: text/html`.

## Production Origin Access Control

- Origin type: `s3`
- Signing behavior: `always`
- Signing protocol: `sigv4`
- Description: Created by CloudFront

## Production S3 Bucket Policy

The bucket policy:

- Allows the CloudFront service principal
- Allows only `s3:GetObject`
- Limits access to production bucket objects
- Restricts access using the production CloudFront distribution ARN
- Uses an `ArnLike` condition
- Does not provide public write access
- Does not make the bucket public

## DNS and Certificates

- Route 53 hosted zones found: None
- ACM certificates in `us-east-1` found: None
- Custom CloudFront aliases found: None
- Current production access uses the default CloudFront domain

## Terraform Separation

- A production Terraform environment does not currently exist.
- Only `infra/environments/dev` currently exists.
- Production identifiers were not found in development Terraform state.
- Development and production resources remain separate.
- No Terraform imports were performed.

## Differences Between Production and the Development Module

| Setting | Production | Development module |
|---|---|---|
| CloudFront price class | `PriceClass_All` | `PriceClass_100` |
| Allowed methods | `GET`, `HEAD` | `GET`, `HEAD`, `OPTIONS` |
| Cached methods | `GET`, `HEAD` | `GET`, `HEAD` |
| Bucket policy condition | `ArnLike` | `StringEquals` |
| S3 versioning | Disabled | Enabled |
| S3 encryption | `AES256` | `AES256` |
| Bucket tags | None | Required Terraform tags |
| S3 Block Public Access | Enabled | Enabled |
| OAC signing | `always`, `sigv4` | `always`, `sigv4` |
| Default root object | `index.html` | `index.html` |
| Viewer protocol policy | `redirect-to-https` | `redirect-to-https` |

## Import Risks

A production import must not proceed until the Terraform configuration matches the existing production resources closely enough to avoid destructive or unexpected changes.

Specific risks include:

- Enabling versioning when production currently has it disabled
- Changing the CloudFront price class
- Adding `OPTIONS` to allowed methods
- Changing the bucket policy condition from `ArnLike` to `StringEquals`
- Adding or changing tags
- Replacing the existing OAC
- Replacing or recreating the CloudFront distribution
- Modifying the production bucket policy
- Accidentally managing production resources from the development state
- Losing or overwriting the existing production website objects

## Required Pre-Import Work

Before any production import:

1. Create a separate production Terraform environment.
2. Configure a separate production remote-state key.
3. Back up production resource configuration and Terraform state.
4. Preserve the current production website objects.
5. Decide whether Terraform should match production exactly first or intentionally change settings later.
6. Add production-specific variables for:
   - Bucket name
   - CloudFront price class
   - Allowed methods
   - Versioning
   - Tags
7. Determine whether the existing OAC should be imported or referenced.
8. Prepare exact Terraform resource addresses and import IDs.
9. Review an import-only plan.
10. Stop if Terraform proposes replacement or destruction.
11. Do not apply production changes until the imported state produces a reviewed plan.

## Stop Conditions

Stop immediately if Terraform proposes:

- Destroying or replacing the production S3 bucket
- Destroying or replacing the production CloudFront distribution
- Destroying or replacing the production OAC
- Deleting or overwriting website objects
- Making S3 public
- Changing DNS or certificates
- Mixing production resources into development state
- Modifying unrelated IAM resources
- Applying an unreviewed plan

## Decision

Production resources were inventoried successfully.

Do not import production today. The next step is production-environment and import planning only.
