# AWS Resource Inventory — July 18, 2026

## S3

- Bucket purpose: Store the static portfolio website files.
- Region: `us-east-1`.
- Public access status: All four S3 Block Public Access controls are enabled.
- Website source folder: Repository directory `website/`.
- Website files present: `index.html` and `styles.css`.
- Direct S3 access result: HTTP `403`; anonymous access remains blocked.

## CloudFront

- Distribution purpose: Public HTTPS and CDN entry point for the portfolio.
- Origin type: Private Amazon S3 origin.
- Origin Access Control: Configured for S3 with `always` signing and SigV4.
- Default root object: `index.html`.
- HTTPS status: Enabled using the CloudFront default certificate.
- Last invalidation tested: Completed on July 17, 2026.

## IAM / OIDC

- OIDC provider exists: Yes; one GitHub Actions OIDC provider was found.
- Deployment role exists: Yes; a dedicated portfolio deployment role exists.
- Trust restricted to: GitHub Actions, repository `2aron41/aws-serverless-portfolio`, branch `main`, and audience `sts.amazonaws.com`.
- Permissions restricted to: Required portfolio S3 deployment operations and CloudFront invalidation operations.
- Administrator access: Not used.

## GitHub Actions

- OIDC test workflow: `.github/workflows/aws-oidc-test.yml`.
- Validation workflow: `.github/workflows/validate-portfolio.yml`.
- Deployment workflow: `.github/workflows/deploy-portfolio.yml`.
- Validation before deployment: Yes.
- S3 sync: Yes; handled by the deployment workflow.
- CloudFront invalidation: Yes; handled after S3 synchronization.

## Redaction and Security

Account IDs, full ARNs, bucket names, distribution IDs, and Origin Access Control IDs are intentionally omitted from this public inventory.

## Inventory Result

The live portfolio remains manually created and is not yet managed by Terraform. This inventory will be used to design and compare a safe dev Terraform configuration.
