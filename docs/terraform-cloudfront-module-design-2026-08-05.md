# Terraform CloudFront Module Design — August 5, 2026

## Goal

Plan how CloudFront and Origin Access Control should eventually be added to the reusable static-site Terraform module.

## Current Module

Currently manages:

- S3 bucket
- S3 Block Public Access
- S3 versioning
- S3 default encryption
- Required tags
- Input validation
- Basic outputs
- Native Terraform tests
- GitHub Actions CI

## Future CloudFront Resources

- CloudFront distribution
- Origin Access Control
- S3 bucket policy allowing CloudFront access
- CloudFront default root object
- Default cache behavior
- Viewer protocol policy
- Allowed methods
- Cached methods
- HTTPS settings
- Outputs needed by GitHub Actions

## Required Inputs

- `enable_cloudfront`
- `default_root_object`
- `cloudfront_price_class`
- `allowed_methods`
- `cached_methods`
- `viewer_protocol_policy`
- `tags`

The first implementation should begin with only the safest placeholder variables. Method and protocol variables should wait until the expected CloudFront behavior is researched and tested.

## Required Outputs

- CloudFront distribution ID
- CloudFront domain name
- S3 bucket regional domain name
- Origin Access Control ID

The distribution ID is required by the GitHub Actions deployment workflow when creating CloudFront invalidations.

## Major Risks

- Accidentally replacing the live distribution
- Breaking HTTPS
- Breaking private S3-origin access
- Creating an unsafe or public bucket policy
- Allowing the wrong CloudFront distribution to access S3
- Changing cache behavior unexpectedly
- Breaking GitHub Actions invalidation
- Changing aliases, certificates, or DNS unexpectedly
- Creating unnecessary cost or global resources
- Importing resources before Terraform configuration matches AWS

## Current Decision

Do not add CloudFront to production Terraform yet.

Day 20 introduces planning, placeholder inputs, validation, documentation, and mocked tests only. It does not create a CloudFront distribution, Origin Access Control, or S3 bucket policy.

## Next Safe Step

Research and model the required resource relationships before testing CloudFront infrastructure in development.

The eventual design should prove that:

- The S3 bucket remains private.
- All four S3 Block Public Access protections remain enabled.
- CloudFront uses the bucket regional domain name as its S3 origin.
- Origin Access Control uses authenticated signed requests.
- The bucket policy grants only the required read access.
- Access is restricted to the intended CloudFront distribution.
- HTTP requests redirect to HTTPS.
- GitHub Actions can use the distribution ID for invalidations.
- CloudFront remains disabled by default until explicitly enabled.
- No production import occurs until the code matches the existing distribution.
