# AWS Serverless Portfolio

> **Status: Planned Project**

This repository will contain a serverless portfolio application built using Python and Amazon Web Services.

## Planned Features

* Serverless backend
* Cloud-hosted portfolio content
* API endpoints
* Database integration
* Monitoring and logging
* Automated deployment

## Planned Technologies

* Python
* AWS Lambda
* Amazon API Gateway
* Amazon DynamoDB
* Amazon S3
* Amazon CloudWatch
* GitHub Actions

## Purpose

This project will demonstrate my ability to design, deploy, and document a practical serverless application in AWS.

Development will begin after I complete the required cloud, Linux, Python, and Git foundations.

## Deployment Status

Current status: Live on AWS through CloudFront.

Current deployment method:

- Manual upload to private S3 bucket
- Manual CloudFront invalidation
- Direct S3 access blocked
- HTTPS served through CloudFront

Next deployment improvement:

- GitHub Actions CI/CD using AWS OIDC and least-privilege permissions
