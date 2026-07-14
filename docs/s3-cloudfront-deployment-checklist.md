# S3 + CloudFront Deployment Checklist

## Goal

Deploy a secure static portfolio website using Amazon S3 for storage and Amazon CloudFront for HTTPS delivery.

## Planned Services

- Amazon S3
- Amazon CloudFront
- AWS Certificate Manager
- Amazon Route 53
- AWS IAM
- Amazon CloudWatch

## Step 1: Create S3 Bucket

- Create a globally unique bucket name.
- Use `us-east-1` as the initial project Region.
- Disable ACLs using Bucket owner enforced.
- Keep Block Public Access enabled.
- Use SSE-S3 default encryption.
- Do not enable public S3 website hosting.

Status: Completed.

## Step 2: Upload Static Website Files

- Upload `index.html` and `styles.css`.
- Place both files at the top level of the bucket.
- Do not upload credentials or private information.

Status: Completed.

## Step 3: Keep S3 Bucket Private

- Keep S3 Block Public Access enabled.
- Do not use public-read ACLs.
- Do not allow anonymous uploads, changes, or deletions.
- Confirm the direct S3 object URL returns Access Denied.

Status: Completed.

## Step 4: Create CloudFront Distribution

- Choose the private S3 bucket as the origin.
- Use the recommended private-origin settings.
- Set `index.html` as the default root object.
- Skip AWS WAF for the current small project to avoid unnecessary cost.

Status: Completed.

## Step 5: Connect CloudFront to S3

- Use Origin Access Control.
- Allow CloudFront to update the S3 bucket policy.
- Permit the CloudFront distribution to read the website objects.
- Keep CloudFront as the public entry point.

Status: Completed.

## Step 6: Configure HTTPS with ACM

- The default CloudFront domain already supports HTTPS.
- Request an ACM certificate when adding a custom domain.
- Request the CloudFront certificate in `us-east-1`.
- Validate the domain using DNS validation.

Status: Planned.

## Step 7: Connect Custom Domain with Route 53

- Register or use an existing domain.
- Create or use a Route 53 hosted zone.
- Add the domain as an alternate domain name in CloudFront.
- Create an alias record pointing to CloudFront.

Status: Planned.

## Step 8: Test Final URL

- Confirm the CloudFront website loads.
- Confirm `index.html` loads automatically.
- Confirm the CSS styling loads.
- Confirm HTTPS works.
- Confirm direct S3 access returns Access Denied.
- Test the website on desktop and mobile.

Status: Completed for the CloudFront domain.

## Security Decisions

- The S3 bucket remains private.
- Public write access is prohibited.
- CloudFront serves the website.
- Origin Access Control authorizes CloudFront to read S3.
- HTTPS is enabled.
- No AWS secrets are stored in GitHub.
- Root is not used for everyday AWS work.
- MFA and AWS cost alerts are enabled.

## Questions I Still Have

- Which custom domain should be used?
- How should deployments be automated?
- How do CloudFront cache invalidations work?
- When should the infrastructure be recreated with Terraform?
