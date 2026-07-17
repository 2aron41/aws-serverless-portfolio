# Portfolio Deployment Evidence — July 16, 2026

## Deployment Type

Secure GitHub Actions deployment using AWS OpenID Connect and temporary AWS credentials.

## Objective

Replace the manual S3 upload process with a repeatable workflow that validates the website, authenticates securely, deploys to Amazon S3, invalidates Amazon CloudFront, and verifies the live result.

## Source Configuration

- Repository: `2aron41/aws-serverless-portfolio`
- Approved branch: `main`
- Website source: `website/`
- Required files:
  - `website/index.html`
  - `website/styles.css`

## AWS Resources

- AWS account: `510497448584`
- Region: `us-east-1`
- S3 bucket: `2aron41-aws-portfolio-20260713`
- CloudFront distribution: `EUWNERX790PYN`
- CloudFront domain: `d1wnw5kep14m5j.cloudfront.net`
- Default root object: `index.html`
- Origin Access Control: `EN0GI1GZOD0R1`

## Initial Architecture Verification

Before creating the workflow, I confirmed:

- The private S3 bucket contained `index.html` and `styles.css`.
- All four S3 Block Public Access settings were enabled.
- CloudFront used the private S3 origin through Origin Access Control.
- CloudFront redirected visitors to HTTPS.
- The CloudFront root returned `HTTP 200`.
- `index.html` returned `HTTP 200`.
- `styles.css` returned `HTTP 200`.
- Direct S3 access returned `HTTP 403`.

## GitHub OIDC Configuration

Created the AWS IAM OIDC provider:

```text
token.actions.githubusercontent.com

```

Configured audience:

```text
sts.amazonaws.com
```

GitHub Actions can now receive temporary AWS credentials without storing permanent access keys.

## IAM Deployment Role

Role:

```text
GitHubActions-AWSServerlessPortfolio-DeployRole
```

Permissions policy:

```text
GitHubActions-AWSServerlessPortfolio-DeployPolicy
```

Maximum session duration:

```text
3600 seconds
```

## Trust-Policy Restriction

The role can only be assumed by:

```text
repo:2aron41/aws-serverless-portfolio:ref:refs/heads/main
```

The expected audience is:

```text
sts.amazonaws.com
```

This restricts deployment access to the exact repository and `main` branch.

## Least-Privilege Permissions

### S3 Bucket

Allowed actions:

- `s3:GetBucketLocation`
- `s3:ListBucket`

Restricted resource:

```text
arn:aws:s3:::2aron41-aws-portfolio-20260713
```

### S3 Objects

Allowed actions:

- `s3:GetObject`
- `s3:PutObject`
- `s3:DeleteObject`

Restricted resource:

```text
arn:aws:s3:::2aron41-aws-portfolio-20260713/*
```

### CloudFront

Allowed actions:

- `cloudfront:CreateInvalidation`
- `cloudfront:GetInvalidation`

Restricted resource:

```text
arn:aws:cloudfront::510497448584:distribution/EUWNERX790PYN
```

The role does not have administrator access or permission to manage unrelated AWS resources.
## GitHub Actions Workflows

### OIDC Authentication Test

Workflow file:

```text
.github/workflows/aws-oidc-test.yml
```

Purpose:

- Request a GitHub OIDC token.
- Assume the expected AWS IAM role.
- Confirm the AWS account.
- Confirm the expected assumed-role identity.

The workflow uses:

```text
aws-actions/configure-aws-credentials@v6
```

### Production Deployment

Workflow file:

```text
.github/workflows/deploy-portfolio.yml
```

Workflow permissions:

```yaml
permissions:
  id-token: write
  contents: read
```

Third-party actions:

```text
actions/checkout@v7
aws-actions/configure-aws-credentials@v6
```

## Deployment Process

The production workflow:

1. Requires the `main` branch.
2. Checks out the repository.
3. Confirms `website/index.html` and `website/styles.css` exist and are not empty.
4. Authenticates to AWS through OIDC.
5. Verifies the expected AWS account and assumed role.
6. Previews the S3 synchronization using `--dryrun`.
7. Synchronizes `website/` to the private S3 bucket.
8. Removes obsolete destination objects using `--delete`.
9. Verifies the required objects exist in S3.
10. Creates a CloudFront invalidation for `/*`.
11. Waits for invalidation completion.
12. Downloads the live HTML and CSS.
13. Compares the live files with the repository.
14. Verifies the CloudFront root returns `HTTP 200`.
15. Verifies direct S3 access returns `HTTP 403`.

## S3 Deletion Decision

The initial deployment plan delayed `s3:DeleteObject` and `--delete` until the behavior was reviewed.

Deletion was approved because:

- The source is restricted to the exact `website/` directory.
- The destination is restricted to the exact portfolio bucket.
- Required files are validated before AWS authentication.
- A dry-run preview occurs before synchronization.
- The role cannot delete the bucket itself.
- Object deletion is limited to this single bucket.
- Post-deployment checks verify the required files still exist.
- Live CloudFront files are compared with the repository.

## Workflow Commits

- `1bde473` — Add GitHub Actions OIDC authentication test
- `b49ed1b` — Upgrade AWS credentials action to v6
- `a7997f5` — Add secure AWS portfolio deployment workflow
- `2e1493f` — Add controlled deployment failure exercise

## Successful OIDC Test

- Commit: `b49ed1b`
- Result: Success
- Run ID: `29547233314`

GitHub successfully assumed:

```text
GitHubActions-AWSServerlessPortfolio-DeployRole
```

No permanent AWS access keys were required.

## Initial Automated Deployment

- Commit: `a7997f5`
- Result: Success
- Duration: 39 seconds
- Run ID: `29547739994`

The workflow successfully:

- Authenticated through OIDC.
- Synchronized the website files to S3.
- Verified the required S3 objects.
- Created a CloudFront invalidation.
- Waited for invalidation completion.
- Verified the live website.
- Confirmed direct S3 access remained blocked.

## Controlled Failure Exercise

A Boolean workflow input named `run_failure_test` was added.

When enabled, the workflow intentionally exits before:

- Repository checkout
- AWS authentication
- S3 synchronization
- CloudFront invalidation

Failure evidence:

- Commit: `2e1493f`
- Result: Expected failure
- Duration: 10 seconds
- Run ID: `29548252773`
- Exit code: `1`
- Error: `Intentional Day 8 failure test.`

This proved an early workflow failure stops later deployment steps before AWS resources are modified.

## Recovery Test

A new workflow run was started with the controlled-failure option disabled.

- Commit: `2e1493f`
- Result: Success
- Duration: 40 seconds
- Run ID: `29548323871`

This proved the workflow could recover and deploy successfully after the controlled failure.
## Final Integrity Verification

### Repository State

The local `main` branch was synchronized with `origin/main`.

### Credential Scan

```text
PASS: No obvious AWS credentials found in tracked non-Markdown files.
```

No AWS access-key ID or secret-access-key values were found in the tracked workflow or website files.

### HTML SHA-256

Repository and live CloudFront checksum:

```text
78416ca59873880f448faff14f372e6caa11b35531cf74e7e1d0c72973879e38
```

### CSS SHA-256

Repository and live CloudFront checksum:

```text
9d7a013b2350dc37028829c1459be3a658bf6fb642d9995bcbafe5be626605ea
```

The matching checksums proved the deployed HTML and CSS were identical to the repository versions.

### Exact File Comparison

```text
PASS: Live index.html matches the repository.
PASS: Live styles.css matches the repository.
```

### HTTP Verification

```text
CloudFront root: HTTP 200
CloudFront index.html: HTTP 200
CloudFront styles.css: HTTP 200
Direct S3 index.html: HTTP 403
```

These results confirmed that CloudFront served the website successfully while direct public S3 access remained blocked.

## Problems Encountered

- The first OIDC workflow used `aws-actions/configure-aws-credentials@v5`.
- GitHub displayed a Node.js 20 deprecation warning.
- Rerunning the original workflow reused the old commit and continued using version 5.
- Several normal deployment runs were started before the controlled-failure input was enabled.
- Long terminal pastes occasionally became garbled while creating documentation.

## Resolution

- Upgraded the AWS credentials action to version 6.
- Started a new workflow run from the updated commit instead of rerunning the old commit.
- Confirmed the new OIDC run succeeded without the Node.js 20 warning.
- Enabled the controlled-failure Boolean input in a new deployment run.
- Confirmed the intentional failure stopped before AWS authentication.
- Started another new run with the failure option disabled.
- Confirmed the recovery deployment succeeded.
- Used the Codespaces editor and smaller documentation sections when long terminal pastes became unreliable.

## Security Results

- No permanent AWS access keys were created for GitHub.
- No AWS credentials were committed to the repository.
- GitHub uses temporary AWS credentials through OIDC.
- The trust policy is limited to the exact repository and `main` branch.
- The permissions policy is limited to the portfolio S3 bucket and CloudFront distribution.
- The workflow requests only `id-token: write` and `contents: read`.
- S3 Block Public Access remains enabled.
- CloudFront remains the public website entry point.
- Direct S3 access remains blocked.

## Skills Demonstrated

- GitHub Actions workflow development
- AWS IAM role configuration
- AWS OIDC identity federation
- Temporary AWS credentials
- IAM trust-policy restrictions
- Least-privilege permissions
- Amazon S3 synchronization
- Amazon CloudFront invalidation
- Bash validation and error handling
- Deployment integrity verification
- Controlled failure testing
- Recovery testing
- Technical documentation

## Possible Résumé Bullet

- Built a secure GitHub Actions deployment pipeline using AWS OIDC and a repository-and-branch-restricted IAM role to synchronize a static portfolio to private S3, invalidate CloudFront, verify live-file integrity, and test controlled failure and recovery without storing long-term AWS keys.

## Final Result

The manual S3 upload process was replaced with a repeatable GitHub Actions deployment workflow using secure temporary AWS credentials.

Day 8 deployment automation is complete.
