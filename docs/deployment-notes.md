# AWS Portfolio Deployment Notes

## Deployment Status

Successfully deployed on July 13, 2026.

## Architecture

```text
User Browser
     |
     | HTTPS
     v
Amazon CloudFront
     |
     | Origin Access Control
     v
Private Amazon S3 Bucket
```

## AWS Resources

### Amazon S3

- Stores the static website files.
- Block Public Access remains enabled.
- ACLs are disabled.
- Objects are encrypted using SSE-S3.
- Direct public access returns Access Denied.

### Amazon CloudFront

- Delivers the website globally.
- Provides HTTPS.
- Uses Origin Access Control to access the private S3 bucket.
- Uses `index.html` as the default root object.
- AWS WAF was not enabled to avoid unnecessary costs for this project.

### AWS IAM

- Root-user MFA is enabled.
- Daily AWS work uses the `aaron-admin` IAM user.
- MFA is enabled for the administrator user.
- No root access keys were created.

### Cost Protection

- AWS Free Tier usage alerts are enabled.
- A zero-spend budget was created.
- Current recorded spend at deployment was $0.00.

## Validation Tests

- CloudFront website: Working
- HTTPS: Working
- CSS styling: Working
- Direct S3 object URL: Access Denied
- S3 bucket public access: Blocked

## Security Decisions

1. The S3 bucket remains private.
2. CloudFront is the only public entry point.
3. Origin Access Control grants CloudFront permission to read the S3 objects.
4. Root credentials are reserved for account-level administration.
5. MFA protects both the root user and administrator account.

## Future Improvements

- Add a custom domain.
- Add an AWS Certificate Manager certificate.
- Automate deployments using GitHub Actions.
- Manage infrastructure using Terraform.
- Add CloudFront cache invalidation to the deployment workflow.
