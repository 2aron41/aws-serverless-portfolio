# GitHub Actions Deployment Plan

## Goal

Automatically deploy portfolio updates when approved changes are pushed to the `main` branch.

The deployment must use AWS OIDC and temporary credentials instead of permanent AWS access keys.

## Approved Deployment Scope

- GitHub repository: `2aron41/aws-serverless-portfolio`
- Approved branch: `main`
- Website source directory: `website/`
- S3 destination bucket: `2aron41-aws-portfolio-20260713`
- CloudFront distribution: `EUWNERX790PYN`
- CloudFront domain: `d1wnw5kep14m5j.cloudfront.net`
- Default root object: `index.html`

## Current Manual Workflow

1. Edit files inside `website/`.
2. Preview and validate the website.
3. Commit and push changes to GitHub.
4. Upload `index.html` and `styles.css` to the private S3 bucket.
5. Confirm the correct S3 object names, sizes, and modified times.
6. Create a CloudFront invalidation.
7. Wait for the invalidation to complete.
8. Test the CloudFront URL.
9. Confirm direct S3 access is still blocked.

## Future Automated Workflow

1. Push an approved change to `main`.
2. GitHub Actions starts.
3. The workflow checks out the repository.
4. The workflow validates the files in `website/`.
5. GitHub authenticates to AWS using OIDC.
6. AWS provides temporary credentials for the deployment role.
7. The workflow confirms its AWS identity.
8. The workflow synchronizes `website/` files to the private S3 bucket.
9. The workflow creates a CloudFront invalidation.
10. The workflow verifies the live CloudFront website.
11. The workflow confirms direct S3 access remains blocked.
12. GitHub Actions reports success or failure.

## Planned Deployment Actions

The future workflow will perform actions equivalent to:

- Synchronize files from `website/` to `s3://2aron41-aws-portfolio-20260713/`
- Create a CloudFront invalidation for distribution `EUWNERX790PYN`

The first implementation should not use S3 synchronization deletion until deletion behavior has been tested and documented.

## Required AWS Permissions

The deployment role should only be able to:

- List the specific portfolio S3 bucket when required
- Upload and replace objects inside the specific portfolio bucket
- Read object metadata when required for verification
- Create invalidations for the specific CloudFront distribution

Object deletion permission should only be added later if an approved deployment design requires it.

The deployment role must not have administrator access.

## Trust Policy Requirements

The IAM role trust policy must restrict access to:

- GitHub's AWS OIDC provider
- Repository `2aron41/aws-serverless-portfolio`
- Branch `main`, or a specifically approved GitHub environment
- The expected OIDC audience for AWS

Requests from another repository or an unapproved branch must be rejected.

## GitHub Workflow Permissions

The workflow should request only:

- `contents: read` to check out the repository
- `id-token: write` to request an OIDC token

It should not receive unnecessary write access to repository contents, issues, pull requests, or packages.

## Security Requirements

- No long-term AWS access keys in GitHub
- No AWS credentials committed to the repository
- OIDC authentication using temporary credentials
- Least-privilege IAM deployment role
- Deployment restricted to the approved repository and branch or environment
- Permissions restricted to the exact S3 bucket and CloudFront distribution
- S3 Block Public Access must remain enabled
- CloudFront must remain the public website entry point
- Workflow logs must not expose credentials or sensitive values
- Third-party GitHub Actions must be reviewed before use


## Validation Requirements

Before AWS authentication or deployment, the workflow should verify:

- The source directory is exactly `website/`
- `website/index.html` exists
- `website/styles.css` exists
- Both required files are not empty
- No incorrectly named `index-*.html` file exists
- The workflow is running from repository `2aron41/aws-serverless-portfolio`
- The deployment originated from the approved `main` branch or approved environment

After deployment, the workflow should verify:

- The CloudFront URL responds successfully
- The expected homepage content appears
- The stylesheet loads successfully
- The CloudFront invalidation request was accepted
- Direct S3 access still returns an access-denied response
- S3 Block Public Access was not changed

## Controlled Failure Exercise

A realistic failure must be introduced before the automated workflow is considered complete.

Planned failure:

1. Temporarily make the validation step look for `website/home.html` instead of `website/index.html`.
2. Run the workflow through a controlled manual test or test branch.
3. Confirm that validation fails before AWS authentication.
4. Confirm that no S3 files or CloudFront settings are changed.
5. Record the failed step and error message.
6. Restore validation to require `website/index.html`.
7. Rerun the workflow.
8. Confirm validation passes and the deployment recovers successfully.

This test proves that file validation can stop an unsafe or incomplete deployment before AWS resources are modified.

## Risks

- Synchronizing the wrong source directory
- Deploying from an unapproved branch
- Uploading incomplete or empty files
- Accidentally deleting required S3 objects
- Using the wrong S3 bucket or CloudFront distribution
- Invalidating more paths than necessary
- Giving the deployment role excessive permissions
- Using an overly broad OIDC trust policy
- Using unreviewed third-party GitHub Actions
- Reporting success without verifying the live website
- Accidentally weakening the private S3 configuration

## Recovery Plan

If a deployment or validation step fails:

1. Stop all later deployment steps.
2. Review the failed step and its logs.
3. Confirm that no credentials were exposed.
4. Confirm the repository, branch, and source directory.
5. Check required file names, file sizes, and validation results.
6. Confirm the exact S3 bucket and CloudFront distribution.
7. Correct the repository files or workflow configuration.
8. Rerun validation before attempting deployment again.
9. Verify the CloudFront website after recovery.
10. Confirm direct S3 access remains blocked.
11. Document the failure, root cause, correction, and evidence.

## Questions Before Implementing

- Should deployment run automatically on every push to `main`, or require a protected GitHub environment?
- Should the first workflow invalidate `/*`, or only changed website paths?
- Which exact S3 permissions are required for synchronization without deletion?
- Should deployment verification search for a unique value from the updated homepage?
- Should the workflow wait until the CloudFront invalidation reaches `Completed`?
- How should the workflow verify that direct S3 access remains blocked?
- Which GitHub Actions versions or commit SHAs should be approved?
- Should branch protection be enabled before live automated deployment?

---

---

## Implementation Status — July 16, 2026

**Status: Completed**

The secure GitHub Actions deployment plan was implemented and validated.

## Implemented AWS Identity Configuration

- GitHub OIDC provider created in AWS IAM
- Audience configured as `sts.amazonaws.com`
- Deployment role:
  - `GitHubActions-AWSServerlessPortfolio-DeployRole`
- Permissions policy:
  - `GitHubActions-AWSServerlessPortfolio-DeployPolicy`
- Trust policy restricted to:
  - Repository: `2aron41/aws-serverless-portfolio`
  - Branch: `main`

## Implemented Workflows

- `.github/workflows/aws-oidc-test.yml`
- `.github/workflows/deploy-portfolio.yml`

## Final Trigger Decision

The production workflow currently uses `workflow_dispatch`.

This keeps deployment manually controlled while the pipeline matures. Automatic deployment can be considered after branch protection or a protected GitHub environment is configured.

## Final S3 Synchronization Decision

The workflow uses:

```bash
aws s3 sync website/ s3://2aron41-aws-portfolio-20260713/ --delete
```

Deletion was approved after implementing:

- Required-file validation
- Exact source and destination restrictions
- A synchronization dry run
- Least-privilege object permissions
- Post-deployment S3 object checks
- Live-file comparison through CloudFront

## Final CloudFront Decision

The workflow invalidates:

```text
/*
```

It waits until the invalidation completes before checking the live website.

## Final Verification

The workflow confirms:

- The expected AWS account and assumed IAM role
- Required S3 objects exist
- CloudFront returns `HTTP 200`
- Live HTML and CSS match the repository
- Direct S3 access returns `HTTP 403`

## Controlled Failure and Recovery

The `run_failure_test` input intentionally stops the workflow before AWS authentication.

Results:

- Controlled failure: Expected failure
- AWS authentication and deployment: Skipped
- Recovery deployment: Success
- Live website after recovery: Verified

## Implementation Evidence

- Full evidence: `docs/deployment-evidence-2026-07-16.md`
- OIDC test commit: `b49ed1b`
- Initial deployment commit: `a7997f5`
- Failure-test commit: `2e1493f`

## Remaining Hardening Opportunities

- Add a protected GitHub production environment.
- Require production deployment approval.
- Add branch protection to `main`.
- Pin third-party actions to immutable commit SHAs.
- Add CloudTrail and CloudWatch monitoring.
- Evaluate selective CloudFront invalidations.
- Manage IAM, S3, and CloudFront through Terraform.
