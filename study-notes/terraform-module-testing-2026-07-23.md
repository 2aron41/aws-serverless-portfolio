# Terraform Module Testing Notes

## What is module testing?

Module testing is the process of verifying that a reusable Terraform module accepts valid inputs, rejects invalid inputs, creates the expected configuration, and does not introduce unexpected infrastructure changes.

## Why should reusable modules be tested?

Reusable modules may be called by multiple environments. Testing helps confirm that the same module behaves consistently and safely before it is trusted with additional infrastructure.

## What could go wrong if a module is reused without testing?

- Invalid resource names could reach the provider.
- Required tags could be missing.
- Public-access protections could be weakened.
- Versioning could be configured incorrectly.
- Resources could be replaced or destroyed unexpectedly.
- Development assumptions could be applied incorrectly to production.

## What should my static-site module guarantee?

- Bucket name is passed correctly.
- Bucket names meet the module validation rules.
- The environment is either `dev` or `prod`.
- Public access remains blocked.
- Versioning can be enabled.
- Required tags are preserved.
- The S3 bucket uses `force_destroy = false`.
- No website upload is handled by Terraform.

## What should not be tested against production first?

New module behavior, resource imports, CloudFront configuration, Origin Access Control, IAM policies, state changes, and rollback procedures should not be tested against production first.

Development should be used to prove that the module configuration, validation rules, state behavior, plans, and recovery procedures work safely.

## My current module-testing plan

1. Run `terraform fmt -recursive`.
2. Run `terraform init` when module or provider configuration changes.
3. Run `terraform validate`.
4. Run `terraform plan` with the real dev inputs.
5. Require the plan to show no infrastructure changes.
6. Test invalid inputs separately without applying.
7. Confirm public-access protection and versioning remain enabled.
8. Confirm all required tags remain present.
9. Keep website uploads in GitHub Actions.
10. Test changes in dev before considering production.

## Day 15 result

- Module variable validation added: Yes
- `terraform validate`: Success
- Final dev plan: `No changes. Your infrastructure matches the configuration.`
- Terraform apply required: No
- Production resources changed: No
