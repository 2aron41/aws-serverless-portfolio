# AWS Serverless Portfolio Project Plan

## Project Status

Planned — no AWS resources have been deployed yet.

## Problem

Recruiters need a fast way to understand my cloud engineering skills, projects, and technical growth.

## User

- Recruiters
- Hiring managers
- Internship reviewers

## Core Features

- Homepage
- About section
- Skills section
- Projects section
- Résumé download
- Contact form
- Links to GitHub and LinkedIn

## AWS Services Planned

### Amazon S3

Store the portfolio’s static website files, images, and résumé.

### Amazon CloudFront

Deliver the website through edge locations with improved performance and HTTPS.

### Amazon Route 53

Manage the project’s custom domain and DNS records.

### AWS Certificate Manager

Provide an SSL/TLS certificate so the website can use HTTPS.

### Amazon API Gateway

Provide an API endpoint for contact-form submissions.

### AWS Lambda

Run serverless Python code when the contact form is submitted.

### Amazon DynamoDB

Store valid contact-form submissions.

### Amazon CloudWatch

Record application logs, errors, metrics, and alarms.

### AWS IAM

Control permissions between services using least privilege.

## Planned Architecture

```text
Visitor
   |
   v
Route 53
   |
   v
CloudFront + AWS Certificate Manager
   |
   v
Amazon S3

Contact Form
   |
   v
API Gateway
   |
   v
AWS Lambda
   |
   v
DynamoDB

Lambda Logs
   |
   v
CloudWatch
