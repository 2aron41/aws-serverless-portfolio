# Current AWS Resources

## Purpose

Document the manually created AWS resources before recreating or importing them with Terraform.

## S3

- Bucket purpose: Store the static portfolio website files.
- Public access: Blocked; the bucket remains private.
- Website files stored: `index.html` and `styles.css`.
- CloudFront access method: Origin Access Control.

## CloudFront

- Purpose: Public HTTPS entry point and content delivery network for the portfolio.
- Origin: Private Amazon S3 bucket.
- Default root object: `index.html`.
- HTTPS: Enabled through the CloudFront domain.
- Invalidation used: `/*` after website deployments.

## IAM

- GitHub OIDC provider: Created and verified.
- Deployment role: Dedicated GitHub Actions deployment role created.
- Trust restricted to: Repository `2aron41/aws-serverless-portfolio`, branch `main`, and audience `sts.amazonaws.com`.
- Permissions restricted to: The portfolio S3 bucket and CloudFront invalidation actions.

## GitHub Actions

- OIDC test workflow: `.github/workflows/aws-oidc-test.yml`.
- Validation workflow: `.github/workflows/validate-portfolio.yml`.
- Deployment workflow: `.github/workflows/deploy-portfolio.yml`.
- Deployment branch: `main`.
- Deployment source directory: `website/`.

## Security Decisions

- S3 bucket remains private.
- CloudFront is the public entry point.
- OIDC avoids long-term AWS keys.
- Deployment role uses least privilege.
- Validation runs before deployment.

## Future Terraform Candidates

- S3 bucket
- S3 Block Public Access configuration
- S3 bucket policy and Origin Access Control access
- CloudFront distribution
- IAM deployment role
- IAM permissions policy
- CloudFront invalidation remains handled by GitHub Actions, not Terraform
