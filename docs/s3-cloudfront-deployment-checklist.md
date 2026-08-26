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

Notes:

- Create a globally unique bucket name.
- Use `us-east-1` as the initial project Region.
- Disable ACLs using Bucket owner enforced.
- Keep Block Public Access enabled.
- Use SSE-S3 default encryption.
- Do not enable public S3 website hosting for this architecture.

Status: Completed.

## Step 2: Upload Static Website Files

Notes:

- Upload `index.html` and `styles.css`.
- Place the files at the top level of the bucket.
- Confirm that both objects uploaded successfully.
- Do not upload credentials, access keys, or private information.

Status: Completed.

## Step 3: Keep S3 Bucket Private

Notes:

- Keep all S3 Block Public Access settings enabled.
- Do not add public-read ACLs.
- Do not grant anonymous users permission to read, upload, overwrite, or delete objects.
- Verify that opening the direct S3 object URL returns Access Denied.

Status: Completed.

## Step 4: Create CloudFront Distribution

Notes:

- Create a CloudFront distribution for a single website.
- Select the private S3 bucket as the origin.
- Do not enable AWS WAF for the initial version because it is unnecessary for the current project and may add cost.
- Set `index.html` as the default root object.

Status: Completed.

## Step 5: Connect CloudFront to S3 Origin

Notes:

- Use CloudFront Origin Access Control.
- Allow CloudFront to update the S3 bucket policy.
- The bucket policy should grant the specific CloudFront distribution permission to read the website objects.
- CloudFront should be the only public entry point.

Status: Completed.

## Step 6: Configure HTTPS with ACM

Notes:

- The default CloudFront domain already provides HTTPS using an AWS-managed CloudFront certificate.
- For a custom domain, request a public ACM certificate.
- A certificate used by CloudFront must be requested or imported in `us-east-1`.
- Validate ownership of the domain, preferably using DNS validation.
- Attach the validated certificate to the CloudFront distribution.

Status: Planned for a future phase.

## Step 7: Connect Custom Domain with Route 53

Notes:

- Register or use an existing domain.
- Create or use a Route 53 hosted zone.
- Add the custom domain as an alternate domain name in CloudFront.
- Create an alias DNS record pointing the domain to the CloudFront distribution.
- Verify that HTTPS works on the custom domain.

Status: Planned for a future phase.

## Step 8: Test Final URL

Notes:

- Confirm that the CloudFront URL loads successfully.
- Confirm that `index.html` loads automatically.
- Confirm that CSS styling loads.
- Confirm that HTTPS is active.
- Confirm that the direct S3 object URL returns Access Denied.
- Test the page on desktop and mobile screen sizes.

Status: Completed for the CloudFront domain.

## Security Decisions

- The S3 bucket does not allow public write access.
- The S3 bucket remains private.
- CloudFront serves the website to users.
- Origin Access Control authorizes CloudFront to read S3 objects.
- HTTPS is enabled.
- No AWS secrets are stored in GitHub.
- Root is not used for daily AWS work.
- MFA protects both the root account and administrator user.
- Cost alerts and an AWS Budget are enabled.

## Questions I Still Have

- Which custom domain should be used for the portfolio?
- How much will domain registration cost?
- Should DNS be managed entirely through Route 53?
- How will future website updates be automatically deployed?
- How should CloudFront cache invalidations be automated?
- When should the infrastructure be recreated using Terraform?