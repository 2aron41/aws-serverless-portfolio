# Terraform CloudFront + OAC Safety Notes — August 6, 2026

## Goal

Prepare to add CloudFront and Origin Access Control to the static-site module safely.

## Current Decision

CloudFront support will be added behind `enable_cloudfront = false` by default.

The initial resource definitions must remain inactive unless the module caller explicitly enables CloudFront.

## Why Disabled by Default

- Prevents accidental CloudFront creation
- Avoids global-resource changes during normal S3 module use
- Allows mocked tests to verify logic before real infrastructure exists
- Preserves the existing development S3 environment
- Keeps production untouched
- Prevents a normal module upgrade from silently adding new resources
- Allows CloudFront inputs, outputs, and resource relationships to be reviewed incrementally

## Required Safety Behavior

When `enable_cloudfront = false`:

- No CloudFront distribution should be planned
- No Origin Access Control should be planned
- No CloudFront S3 bucket policy should be planned
- Existing S3 resources should remain unchanged
- CloudFront-related outputs should return `null`
- Existing module tests should continue to pass
- The real development plan should return no changes

## Stop Conditions

Stop immediately if Terraform proposes:

- Creating CloudFront in the real dev environment unexpectedly
- Creating Origin Access Control unexpectedly
- Attaching a new S3 bucket policy unexpectedly
- Replacing any S3 bucket
- Destroying any resource
- Changing production infrastructure
- Making an S3 bucket public
- Disabling an S3 Block Public Access setting
- Weakening access controls
- Removing encryption or versioning
- Changing resources outside the approved Day 21 scope

## Testing Rules

- Run formatting and validation before testing
- Use mocked Terraform tests before any real AWS plan
- Verify CloudFront resources have zero instances when disabled
- Verify CloudFront outputs are `null` when disabled
- Run the real dev plan only after mocked tests pass
- Do not apply if the real plan contains any changes
- Do not temporarily enable CloudFront in the real dev environment today

## Production Status

Production remains unmanaged by Terraform.

No production imports, plans, applies, CloudFront changes, OAC changes, S3 bucket-policy changes, IAM changes, certificate changes, or DNS changes are permitted during Day 21.
