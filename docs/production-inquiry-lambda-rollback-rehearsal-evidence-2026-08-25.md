# Production Inquiry Lambda Rollback Rehearsal Evidence

**Date:** August 25, 2026

## Objective

Prove that the production inquiry Lambda can be rolled back through Terraform
from immutable version 2 to immutable version 1, verify the service while
running on version 1, and then restore production to version 2 using a
separately reviewed Terraform saved plan.

The rehearsal was required to demonstrate an operational rollback path rather
than merely having rollback-capable infrastructure.

## Starting Production State

Repository commit:

`a00ff66dc38a52208d7d45c61e2aae10417cea84`

Repository state:

- clean
- synchronized with `origin/main`

Terraform state before rollback:

- lineage: `ca7b1441-16c0-360d-89f7-22da6de017fe`
- serial: `19`
- managed resources: `31`

Production Lambda inventory:

- `$LATEST`:
  `wwfLFAaLEuDTR9t0ZOVQw2lSR6MvjEAqJyr0BtukVCo=`
- version 1:
  `x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`
- version 2:
  `wwfLFAaLEuDTR9t0ZOVQw2lSR6MvjEAqJyr0BtukVCo=`
- numbered versions: `2`
- production alias: `live -> 2`

Version 1 was therefore a genuine older immutable rollback target.

## Rollback Configuration Artifact

A controlled rollback artifact was added at:

`infra/environments/prod/rollback-v1.tfvars.example`

Artifact SHA256:

`8568beb0692ad8e31dd34b0339f3e4796522e9c9e541fed18ead0c0ad8762e41`

Contents explicitly set:

`inquiry_lambda_alias_version = "1"`

The artifact is intentionally not auto-loaded by Terraform.

It must be supplied explicitly with:

`-var-file=rollback-v1.tfvars.example`

The normal ignored production `terraform.tfvars` remains:

`inquiry_lambda_alias_version = null`

Normal production tfvars SHA256:

`2c567809f8d8fdf7b99fcc6250d62e4549a4775aef6a15929c9cdbd87a111519`

This design keeps normal production configuration following the latest
Terraform-published version while requiring explicit operator intent for a
rollback.

## Rollback Artifact CI

Rollback artifact commit:

`a00ff66dc38a52208d7d45c61e2aae10417cea84`

Required exact-commit CI:

- Terraform Production Environment Tests: SUCCESS
- Validate Portfolio Website: SUCCESS

The production Terraform workflow remained validation-only.

No Terraform apply occurred through CI.

## Pre-Rehearsal Local Verification

Before the production rehearsal:

- serverless inquiry module tests: 32/32 passing
- production Terraform test: 1/1 passing
- Terraform validation: PASS
- normal production Terraform plan: No changes
- explicit rollback design plan: alias-only `2 -> 1`

The normal configuration did not auto-load the rollback artifact.

## Rollback Design Findings

The initial design audit proved that the existing Terraform variable:

`inquiry_lambda_alias_version`

can pin the `live` alias to an explicit immutable numbered Lambda version.

A disposable simulation with version 1 produced exactly:

`live: 2 -> 1`

Plan summary:

`0 add / 1 change / 0 destroy`

Critical resources were no-op:

- Lambda function
- API Gateway integration
- Lambda alias invoke permission

## Day 50 Recovery Findings

Two configuration-handling issues were discovered safely before production
mutation.

### CLI Variable Quoting

The first CLI simulation passed a value that Terraform interpreted as:

`"\"1\""`

rather than:

`"1"`

Terraform's existing variable validation correctly rejected the malformed
value.

No production or state changes occurred.

The corrected CLI simulation proved the expected alias-only transition.

### Ignored Production tfvars

The real production:

`infra/environments/prod/terraform.tfvars`

is intentionally ignored by:

`*.tfvars`

The tracked:

`terraform.tfvars.example`

remains the repository template.

The temporary local version-1 value was restored exactly to the known
production baseline before proceeding.

Rather than force-adding the ignored production tfvars, Day 50 introduced the
tracked, non-auto-loaded rollback artifact.

## Reviewed Rollback Saved Plan

Fresh post-CI rollback saved plan SHA256:

`c58fe6dc1e77dd919bc85cee9a0faed9b648e7090836dd4b4f30664adbefc763`

Exact managed mutation set:

- `module.serverless_inquiry.aws_lambda_alias.inquiry_live[0]`
  - update in place
  - `function_version = "2" -> "1"`

Plan summary:

`Plan: 0 to add, 1 to change, 0 to destroy.`

Confirmed no-op resources:

- Lambda function
- API Gateway integration
- alias invoke permission

No replacement or destruction was planned.

## Rollback Final Pre-Apply Gates

Immediately before rollback, the following were verified:

- exact Git commit
- clean repository
- successful exact-commit production CI
- correct AWS account and IAM identity
- exact production tfvars hash
- exact rollback artifact hash
- exact saved rollback plan hash
- Terraform state: 31 resources / serial 19
- `$LATEST` code SHA = version 2 code
- immutable version 1 SHA exact
- immutable version 2 SHA exact
- exactly two numbered Lambda versions
- `live -> 2`
- API Gateway invokes the `live` alias
- alias invoke permission intact
- four inquiry alarms `OK` with actions enabled
- saved plan mutation set = alias only
- exact transition = `2 -> 1`

All gates passed.

## Production Rollback

Terraform applied the exact reviewed rollback saved plan.

Result:

`Apply complete! Resources: 0 added, 1 changed, 0 destroyed.`

The applied rollback binary plan was then deleted so it could not be reused.

## Rolled-Back Production Verification

After rollback:

`live -> 1`

Immutable versions remained unchanged.

API Gateway continued invoking the `live` alias.

One controlled invalid production request was sent:

`{}`

Observed response:

- HTTP status: `400`
- body: `{"message": "Invalid inquiry request."}`

CloudWatch execution evidence confirmed that the request executed on:

`Version: 1`

This proved that real production traffic could be routed successfully to the
older immutable version through the Terraform-managed alias.

## State After Rollback

Terraform state after rollback:

- lineage: `ca7b1441-16c0-360d-89f7-22da6de017fe`
- serial: `20`
- managed resources: `31`

All four inquiry alarms remained `OK` with actions enabled.

## Reviewed Restoration Saved Plan

While production intentionally remained on version 1, a fresh normal-config
restoration plan was generated.

Restore saved plan SHA256:

`ecbb2d6f977a9bc6364f4ef3790c1503e967dac912f0919ef7a5c18a9872d6b2`

Exact managed mutation:

- `module.serverless_inquiry.aws_lambda_alias.inquiry_live[0]`
  - update in place
  - `function_version = "1" -> "2"`

Plan summary:

`Plan: 0 to add, 1 to change, 0 to destroy.`

Confirmed no-op resources:

- Lambda function
- API Gateway integration
- alias invoke permission

The restoration plan was preserved without regeneration until its final
pre-apply review.

## Restoration Final Pre-Apply Gates

Before restoration, the following were reverified:

- exact repository commit
- successful exact-commit production CI
- correct AWS identity
- normal tfvars hash exact
- rollback artifact hash exact
- restore saved-plan hash exact
- Terraform state: 31 resources / serial 20
- immutable versions 1 and 2 intact
- production still `live -> 1`
- API integration still alias-based
- alias invoke permission intact
- four alarms healthy
- restore plan mutation set = alias only
- exact transition = `1 -> 2`

All gates passed.

## Production Restoration

Terraform applied the exact reviewed restore plan.

Result:

`Apply complete! Resources: 0 added, 1 changed, 0 destroyed.`

The applied restoration binary plan was deleted immediately afterward.

## Restored Production Verification

After restoration:

`live -> 2`

Immutable Lambda versions remained:

- version 1:
  `x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`
- version 2:
  `wwfLFAaLEuDTR9t0ZOVQw2lSR6MvjEAqJyr0BtukVCo=`

API Gateway continued routing through:

`live`

A second controlled invalid production request was sent:

`{}`

Observed response:

- HTTP status: `400`
- body: `{"message": "Invalid inquiry request."}`

CloudWatch confirmed:

`Version: 2`

The version-2 privacy-safe categorical validation warning was also observed.

## Final Terraform State

Terraform state after restoration:

- lineage: `ca7b1441-16c0-360d-89f7-22da6de017fe`
- serial: `21`
- managed resources: `31`

State progression during the rehearsal:

`19 -> 20 -> 21`

The resource count remained constant at 31.

## Final Monitoring

After restoration, all four inquiry alarms were:

- state: `OK`
- actions enabled: `True`

## Final Terraform Convergence

A normal production Terraform plan returned:

`No changes. Your infrastructure matches the configuration.`

Detailed exit code:

`0`

## Final Production State

Production ended the rehearsal at:

`API Gateway -> live alias -> Lambda version 2`

Version 1 remains preserved as the known-good rollback target.

The tracked explicit rollback artifact remains available for future operator
use.

## Production Request Count

Controlled production requests during the rehearsal:

`2`

- one while production was rolled back to version 1
- one after restoration to version 2

Both returned the expected generic HTTP 400 validation response.

## Day 50 Result

Day 50 proved the complete Terraform-controlled rollback lifecycle:

`version 2 -> version 1 -> version 2`

The exercise demonstrated:

- a real immutable older rollback target
- explicit operator-controlled rollback input
- alias-only production mutation
- no Lambda package mutation during rollback or restore
- no API integration mutation
- no invoke-permission mutation
- functional production verification on both versions
- monitoring remained healthy throughout
- state remained structurally stable
- separate reviewed saved plans for rollback and restoration
- deletion of applied binary plans
- final Terraform convergence
- preserved rollback capability after restoration

## Conclusion

The production inquiry Lambda rollback mechanism is now operationally proven,
not merely architecturally possible.

A future incident can use the tracked explicit rollback artifact to generate a
reviewed Terraform plan that moves the `live` alias to immutable version 1
without changing the Lambda package, API integration, or invocation
permission.

Normal production configuration remains unpinned and converged on version 2.
