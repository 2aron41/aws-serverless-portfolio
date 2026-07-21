# AWS OIDC Implementation Checklist

## Goal

Allow GitHub Actions to deploy the portfolio using short-lived AWS credentials instead of long-term access keys.

## Required AWS Items

- [x] GitHub OIDC identity provider
- [x] IAM deployment role
- [x] Trust policy restricted to this GitHub repository
- [x] Permissions policy restricted to the portfolio S3 bucket and CloudFront distribution

## Trust Policy Requirements

- [x] Allow only GitHub Actions through the configured OIDC provider
- [x] Restrict to repository `2aron41/aws-serverless-portfolio`
- [x] Restrict to branch `main`
- [x] Restrict the audience to `sts.amazonaws.com`

## Permissions Needed

- [x] Synchronize website files to the specific S3 bucket
- [x] Create invalidations for the specific CloudFront distribution

## Permissions Not Needed

- [x] No `AdministratorAccess`
- [x] No IAM user creation
- [x] No S3 bucket deletion
- [x] No CloudFront distribution deletion
- [x] No Route 53 changes
- [x] No billing access

## Pre-Deployment Validation

- [x] `website/index.html` exists
- [x] `website/styles.css` exists
- [x] `website/index-.html` does not exist
- [x] No obvious secrets are present
- [x] Validation runs before deployment

## Post-Deployment Validation

- [x] CloudFront URL loads
- [x] CSS loads
- [x] Direct S3 access remains blocked
- [x] Updated homepage appears

## Implementation Status

The optional Day 8 AWS task was completed and exceeded. The OIDC provider, restricted IAM deployment role, test workflow, deployment workflow, S3 synchronization, and CloudFront invalidation are operational.
