# Production Inquiry Lambda Version 2 Deployment Evidence

**Date:** August 25, 2026

## Objective

Deploy a legitimate second immutable production inquiry Lambda version after
a reviewed application improvement, preserve Lambda version 1 as a genuine
known-good rollback target, and verify production health after deployment.

## Starting Repository State

Final CI-validated repository commit:

`fd30a5655fcc627ac675ef32508ac40bec39046e`

Version-2 application source commit:

`a49bca90482644aca2d3e85fff146fcb42bb4780`

Repository was clean and synchronized with `origin/main`.

## Version-2 Application Change

The inquiry Lambda now records a privacy-safe warning when request validation
fails.

The public API response remains intentionally generic:

`{"message": "Invalid inquiry request."}`

The warning records only the predefined categorical validation reason and
does not intentionally include the submitted visitor name, email address,
message, or raw request body.

Example validation category:

`Email format is invalid.`

## Test-Driven Development Evidence

Existing handler baseline before the new requirement:

- handler tests: 17/17 passing

RED:

- one new privacy-boundary validation logging test added
- handler tests after test addition: 18 total
- result: 17 passing / 1 failing
- precise failure: no WARNING log was emitted

GREEN:

- minimal handler implementation added
- new validation logging test: passing
- full handler suite: 18/18 passing
- Terraform serverless inquiry module tests: 32/32 passing
- production Terraform test: 1/1 passing
- Terraform validation: passing

## CI Coverage Finding

The initial version-2 source push revealed that the Lambda source path was not
included in the serverless or production Terraform workflow path filters.

Only the general portfolio validation workflow initially ran for the
application source commit.

This was treated as a CI coverage gap rather than accepting incomplete
post-CI evidence.

## CI Coverage Improvement

Day 49 added:

`/.github/workflows/python-inquiry-handler-tests.yml`

The existing Terraform workflows were updated so changes under:

`lambda_src/**`

trigger:

- Python Inquiry Handler Tests
- Terraform Serverless Inquiry Module Tests
- Terraform Production Environment Tests

The workflows remain validation-only and contain no direct Terraform apply or
Lambda mutation commands.

CI coverage commit:

`fd30a5655fcc627ac675ef32508ac40bec39046e`

Required exact-commit CI results:

- Python Inquiry Handler Tests: SUCCESS
- Terraform Serverless Inquiry Module Tests: SUCCESS
- Terraform Production Environment Tests: SUCCESS
- Validate Portfolio Website: SUCCESS

## Production Input Gate

Production tfvars SHA256:

`2c567809f8d8fdf7b99fcc6250d62e4549a4775aef6a15929c9cdbd87a111519`

AWS identity:

- account: `510497448584`
- IAM ARN: `arn:aws:iam::510497448584:user/aaron-admin`

## Pre-Deployment Terraform Baseline

Terraform state:

- lineage: `ca7b1441-16c0-360d-89f7-22da6de017fe`
- serial: `18`
- managed resources: `31`

Lambda inventory before deployment:

- `$LATEST` code SHA:
  `x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`
- version `1` code SHA:
  `x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`
- numbered versions: `1`
- `live -> 1`

Version 1 was the current immutable production version before the deployment.

## Monitoring Baseline

All four inquiry alarms were `OK` with actions enabled before deployment:

- inquiry API 4xx
- inquiry API 5xx
- inquiry Lambda errors
- inquiry Lambda throttles

## Reviewed Post-CI Saved Plan

Exact post-CI saved-plan SHA256:

`25817e37307e9b5272f7a85d888dac72f984d18fcd8818055cd04f0041954f43`

The reviewed mutation set contained exactly two managed in-place updates:

1. `module.serverless_inquiry.aws_lambda_function.inquiry[0]`
2. `module.serverless_inquiry.aws_lambda_alias.inquiry_live[0]`

Plan summary:

`Plan: 0 to add, 2 to change, 0 to destroy.`

No resource replacement or destruction was planned.

## Planned Lambda Change

Old production code SHA:

`x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`

Reviewed new code SHA:

`wwfLFAaLEuDTR9t0ZOVQw2lSR6MvjEAqJyr0BtukVCo=`

Unchanged Lambda settings included:

- runtime: `python3.12`
- handler: `inquiry_handler.lambda_handler`
- `publish = true`

Terraform therefore planned to publish a new immutable Lambda version and
move the existing `live` alias to that newly published version.

## Final Pre-Apply Gates

Immediately before apply, the following were reverified:

- exact Git commit
- clean repository
- exact saved-plan SHA256
- exact production tfvars SHA256
- exact AWS account and IAM user
- Terraform lineage
- Terraform serial `18`
- Terraform resource count `31`
- `$LATEST` old code SHA
- version 1 old code SHA
- exactly one numbered version
- `live -> 1`
- four inquiry alarms `OK`
- exact two-resource saved-plan mutation set

All final gates passed.

## Production Apply

Terraform applied the exact reviewed saved plan.

Apply result:

`Apply complete! Resources: 0 added, 2 changed, 0 destroyed.`

The applied binary plan was deleted immediately afterward and must not be
reused.

## Lambda Version Verification

Post-deployment Lambda inventory:

- `$LATEST`:
  `wwfLFAaLEuDTR9t0ZOVQw2lSR6MvjEAqJyr0BtukVCo=`
- version `1`:
  `x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`
- version `2`:
  `wwfLFAaLEuDTR9t0ZOVQw2lSR6MvjEAqJyr0BtukVCo=`

Numbered versions:

`2`

Production alias:

`live -> 2`

Version 1 remains immutable and is now a genuine previous known-good rollback
target.

## API Routing Verification

API Gateway integration continues to invoke:

`aws-serverless-portfolio-prod-inquiry:live`

The API was not changed to invoke a numbered Lambda version directly.

## Lambda Permission Verification

Alias permission remains present:

`AllowInquiryApiGatewayInvokeLiveAlias`

Principal:

`apigateway.amazonaws.com`

Action:

`lambda:InvokeFunction`

The permission remains scoped to the `live` alias and the exact production
API Gateway POST inquiry route.

The base Lambda function resource policy remains absent.

## Controlled Production Validation

Exactly one controlled invalid production request was sent after deployment.

Request body:

`{}`

Observed response:

- HTTP status: `400`
- body: `{"message": "Invalid inquiry request."}`

The public validation contract therefore remained unchanged.

## Production Logging Verification

CloudWatch recorded the new privacy-safe validation warning.

Observed category:

`Request must contain exactly name, email, and message.`

The warning was verified without intentionally logging the request body or
visitor-submitted content.

## Post-Deployment Terraform State

Terraform state after apply:

- lineage: `ca7b1441-16c0-360d-89f7-22da6de017fe`
- serial: `19`
- managed resources: `31`

The state serial advanced from 18 to 19 while the resource count remained
unchanged.

## Post-Deployment Monitoring

All four inquiry alarms remained:

- state: `OK`
- actions enabled: `True`

## Terraform Convergence

A post-apply Terraform plan returned:

`No changes. Your infrastructure matches the configuration.`

Detailed exit code:

`0`

Production therefore converged fully after deployment.

## Final Repository State

Final repository commit:

`fd30a5655fcc627ac675ef32508ac40bec39046e`

Repository status:

- clean
- synchronized with `origin/main`

## Day 49 Activity Summary

- application source change: YES
- test-first RED/GREEN cycle: YES
- CI coverage improvement: YES
- Terraform apply: YES
- exact saved plan applied: YES
- Terraform additions: 0
- Terraform changes: 2
- Terraform destructions: 0
- controlled production requests: 1
- Lambda version 2 published: YES
- `live -> 2`: YES
- version 1 preserved: YES
- genuine older rollback target available: YES
- post-apply alarms: 4/4 OK
- Terraform convergence: No changes

## Conclusion

Day 49 closed the rollback-readiness gap identified during Day 48.

Production now runs through:

`API Gateway -> live alias -> Lambda version 2`

while immutable Lambda version 1 remains available as a genuine known-good
rollback target.

No rollback rehearsal was performed during Day 49.

A future rollback rehearsal must remain Terraform-controlled, independently
reviewed, and use the explicit alias version override rather than manually
repointing the Lambda alias.
