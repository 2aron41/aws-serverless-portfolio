# AWS Serverless Portfolio

> **Status: Live on AWS with secure GitHub Actions deployment**

This repository contains the live frontend foundation for an AWS serverless portfolio project.

The website is stored in a private Amazon S3 bucket, delivered through Amazon CloudFront over HTTPS, and deployed through GitHub Actions using AWS OpenID Connect.

## Live Site

- CloudFront website: https://d1wnw5kep14m5j.cloudfront.net
- Source repository: `2aron41/aws-serverless-portfolio`

## Current Architecture

```text
Developer
    |
    | Approved repository changes
    v
GitHub Actions
    |
    | OIDC identity token
    v
Least-privilege AWS IAM role
    |
    | Temporary AWS credentials
    v
Private Amazon S3 bucket
    |
    | Origin Access Control
    v
Amazon CloudFront
    |
    | HTTPS
    v
Website visitor
