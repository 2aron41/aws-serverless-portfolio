# Terraform Infrastructure

## Purpose

This folder will eventually manage the long-lived AWS infrastructure for the serverless portfolio project.

## Current Status

Planning only. No production AWS resources are managed by Terraform yet.

## Planned Resources

- S3 bucket
- S3 bucket policy and CloudFront access
- CloudFront distribution
- Origin Access Control
- IAM GitHub Actions deployment role
- IAM deployment permissions policy

## Not Managed by Terraform

- Website file uploads
- CloudFront invalidations
- GitHub Actions workflow execution

Those deployment actions are handled by GitHub Actions.
