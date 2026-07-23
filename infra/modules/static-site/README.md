# Static Site Terraform Module

## Purpose

Reusable Terraform module for managing static website infrastructure consistently across development and production environments.

The module should reduce duplicated Terraform configuration while keeping environment-specific values outside the reusable module.

## Future Inputs

- `project_name`
- `environment`
- `aws_region`
- `bucket_name`
- `enable_versioning`
- `tags`

Additional inputs may be introduced later only when required and safely tested in development.

## Future Resources

- S3 bucket
- S3 public access block
- S3 versioning
- CloudFront Origin Access Control
- CloudFront distribution
- IAM permissions for GitHub Actions deployment

## Not Included

- Website file upload
- CloudFront invalidation
- Application code deployment

Website files should continue to be deployed through GitHub Actions rather than Terraform. Terraform should manage infrastructure, while the deployment workflow should manage frequently changing application files.

## Safety Notes

This module should be tested in development before managing production infrastructure.

Production resources must not be imported, replaced, or modified until:

- The module works correctly in development
- Inputs and outputs are documented
- A development plan shows only expected changes
- State storage and recovery procedures are established
- Production import and migration steps are separately reviewed
- A rollback plan exists

The current development bucket should not be converted into this module until the existing configuration, state, and migration plan have been reviewed carefully.
