# AWS Serverless Portfolio Story

## Problem

Recruiters need a fast way to understand my cloud engineering skills, projects, and technical growth.

## Why This Project Matters

This is not just a personal website. It is a cloud project that shows I can plan, deploy, secure, and document AWS infrastructure.

The goal is to turn my portfolio into proof that I understand cloud architecture, security basics, monitoring, and deployment decisions.

## What I Am Building

A serverless portfolio platform using AWS services.

The first version will focus on hosting a static website. Later versions can add a contact form, backend API, database storage, monitoring, and deployment automation.

## Planned Architecture

Planned AWS services:

- S3
- CloudFront
- Route 53
- ACM
- API Gateway
- Lambda
- DynamoDB
- CloudWatch

S3 will store the website files.

CloudFront will deliver the website faster and more securely through edge locations.

Route 53 will connect the custom domain.

ACM will provide the HTTPS certificate.

API Gateway, Lambda, and DynamoDB may be used later for a contact form or project interaction feature.

CloudWatch will help monitor logs and system behavior.

## Security Decisions

- Use HTTPS through CloudFront and ACM.
- Avoid public write access.
- Do not store secrets in GitHub.
- Use least-privilege IAM permissions.
- Validate input for any future contact form.
- Keep private files out of public S3 access.
- Use CloudTrail and CloudWatch concepts to understand activity and monitoring.

## What I Need to Learn Before Building

- S3 hosting
- S3 bucket policies
- S3 public access controls
- CloudFront distributions
- CloudFront origins
- Route 53 DNS
- ACM certificates
- Lambda functions
- API Gateway routes
- DynamoDB tables
- CloudWatch logs
- Terraform basics
- GitHub Actions deployment

## Evidence I Need to Collect

- Architecture diagram
- Screenshots
- GitHub commits
- Errors encountered
- Fixes applied
- Final live URL
- Cost estimate
- Security notes
- Monitoring notes
- Deployment steps

## Interview Story

This project shows that I am not only building a website. I am learning how to design and explain cloud infrastructure.

I can explain why S3 is used for storage, why CloudFront is used for delivery, why HTTPS matters, and why least privilege is important.

As the project grows, I will document each decision and collect evidence of what I built, what broke, and how I fixed it.
