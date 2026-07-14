# Manual Portfolio Deployment Runbook

## Purpose

This runbook documents the current manual process for updating the AWS portfolio website.

## Architecture

```text
Local website files
        |
        | Manual upload
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
