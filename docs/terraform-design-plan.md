# Terraform Design Plan

## Goal

Move manually created AWS portfolio infrastructure into Infrastructure as Code safely.

## Phase 1: Document current resources

Status: Completed through read-only AWS inspection.

## Phase 2: Create Terraform structure

Status: Completed as a planning-only folder structure.

## Phase 3: Write Terraform for a new test environment

Status: In progress. The dev skeleton exists, but no AWS resource blocks have been added.

## Phase 4: Compare Terraform plan carefully

Status: The skeleton plan was reviewed and proposed only outputs. Real-resource comparison has not started.

## Phase 5: Decide whether to import or recreate

Status: Deferred until the dev configuration is understood and tested.

## Resources to Manage

### S3

Terraform should eventually manage the bucket configuration, public-access protections, tags, and related policies consistently.

### CloudFront

Terraform should manage the long-lived distribution configuration, origin, cache behavior, default root object, and security settings.

### Origin Access Control

Terraform should manage the approved private connection between CloudFront and S3.

### IAM OIDC Role

Terraform should manage the repository and branch trust restrictions and the least-privilege deployment permissions consistently.

## Resources/Actions Terraform Should Not Manage

### Website uploads

Website files change frequently and belong in the GitHub Actions application deployment workflow.

### CloudFront invalidations

Invalidations are deployment actions that should run after GitHub Actions synchronizes updated website files.

## Risks

- Accidentally replacing the live CloudFront distribution
- Accidentally changing S3 public access
- Accidentally weakening IAM permissions
- Accidentally deleting production resources
- Terraform state exposing sensitive details

## Safety Rules

- No `terraform apply` until the plan is understood
- No `terraform destroy` on production resources
- Use a test environment before touching production
- Keep state protected
- Review every IAM change
