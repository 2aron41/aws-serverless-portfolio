# Terraform Production Migration Plan

## Goal

Eventually bring the manually created production portfolio infrastructure under Terraform management safely.

## Current Production Resources

- Private S3 portfolio bucket
- S3 Block Public Access
- CloudFront distribution
- Origin Access Control
- IAM GitHub Actions OIDC provider
- IAM deployment role
- IAM permissions policy

## Current Decision

Do not import production resources yet.

## Why Not Yet

- The dev module currently manages only S3.
- CloudFront is not modeled in Terraform yet.
- Origin Access Control is not modeled in Terraform yet.
- The IAM deployment role and permissions policy are not modeled in Terraform yet.
- The production resource inventory is not yet complete.
- Exact production import commands have not been reviewed.
- Complete rollback procedures have not been written or tested.

## Required Before Production Import

- Remote state working
- Dev module tested
- Module input validation complete
- Production resource inventory complete
- Matching Terraform code written
- Existing AWS settings compared with Terraform code
- Import commands planned and reviewed
- Rollback plan written
- Saved pre-import state backup
- Clean pre-import Terraform plan
- No secrets, state, or lock files committed
- Production changes reviewed separately from dev work

## Possible Migration Order

1. Production S3 bucket
2. S3 public access block
3. S3 versioning
4. CloudFront Origin Access Control
5. CloudFront distribution
6. IAM OIDC deployment role and permissions policy

Each resource group should be imported, verified, and documented before moving to the next group.

## Rollback Plan Draft

If Terraform proposes unexpected production changes:

- Stop before apply.
- Do not approve or apply the plan.
- Save the unexpected plan output for investigation.
- Restore the previous Terraform code.
- Re-run `terraform init` if module or backend configuration changed.
- Re-run `terraform plan`.
- Confirm production AWS resources remain unchanged.
- Use the protected state backup only if state recovery is necessary.
- Do not manually edit state without a separately reviewed recovery procedure.

## Biggest Risks

- Accidentally replacing the CloudFront distribution
- Accidentally changing S3 bucket access
- Accidentally weakening IAM permissions
- Accidentally deleting production resources
- Using incorrect Terraform import addresses
- Writing Terraform code that does not match existing AWS settings
- Mixing production migration with unrelated infrastructure changes
- Applying before reviewing a saved plan

## Production Safety Gates

Production import must not begin until:

- The dev module continues to produce a clean plan
- CloudFront and OAC configurations are understood
- IAM trust and permissions policies are documented
- Exact production resource identifiers are recorded
- Import commands are reviewed
- A protected pre-import state backup exists
- The expected post-import plan is understood
- The rollback procedure is complete

## Production Resources Changed

No production resources were changed while creating this plan.
