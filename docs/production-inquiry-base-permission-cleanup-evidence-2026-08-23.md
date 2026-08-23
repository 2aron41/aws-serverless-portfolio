# Production Inquiry Base Invoke Permission Cleanup Evidence

**Date:** August 23, 2026
**Environment:** Production
**Region:** us-east-1

## Objective

Remove the redundant unqualified API Gateway invoke permission after
production traffic had already been migrated to the stable Lambda `live`
alias.

The permission cleanup was intentionally separated from the Day 46 traffic
migration.

## Starting Baseline

Before cleanup:

- API Gateway already targeted the `live` alias.
- `live -> 1`.
- Base and alias-specific invoke permissions both existed.
- Terraform state count was 32.
- Terraform state serial was 17.
- Production Terraform was converged.
- Four inquiry operational alarms were healthy.

## Test-First Contract

Desired behavior:

- inquiry disabled -> no API invoke permission;
- inquiry enabled + alias disabled -> base permission;
- inquiry enabled + alias enabled -> alias permission only.

The RED test required the base permission to be absent when alias routing was
enabled.

RED result:

`31 passed, 1 failed`

Only `lambda_alias_invoke_permission_when_enabled` failed.

After the lifecycle implementation, the module returned:

`32 passed, 0 failed`

Production Terraform test:

`1 passed, 0 failed`

## Cleanup Commit

`498edd8e6a74a825aed008ecae16a7ecd74f5a04`

Commit message:

`Remove redundant inquiry base invoke permission`

Exact files:

- `infra/modules/serverless-inquiry/main.tf`
- `infra/modules/serverless-inquiry/tests/basic.tftest.hcl`

## Continuous Integration

Serverless module CI:

`32660939788 — success`

Production Terraform CI:

`32660939799 — success`

## Applied Saved Plan

Path:

`/tmp/day47-base-permission-post-ci.tfplan`

SHA256:

`5b0d50d46290ba0752f5e61ce375998804a233a96b2854407bda56371272b632`

Plan result:

`0 to add, 0 to change, 1 to destroy`

The only planned and applied deletion was:

`module.serverless_inquiry.aws_lambda_permission.inquiry_api[0]`

AWS statement:

`AllowInquiryApiGatewayInvoke`

No replacement occurred.

## Apply Result

Terraform completed:

`0 added, 0 changed, 1 destroyed`

The redundant unqualified invoke permission was removed.

The alias-specific permission remained:

`AllowInquiryApiGatewayInvokeLiveAlias`

## Production Routing

Production remains:

`API Gateway -> live alias -> Lambda version 1`

Integration ID:

`4ugv6de`

Alias:

`live -> 1`

Lambda code and Lambda version 1 were unchanged.

## Terraform State

Before cleanup:

- resources: 32
- serial: 17

After cleanup:

- resources: 31
- serial: 18

Lineage remained:

`ca7b1441-16c0-360d-89f7-22da6de017fe`

## Functional Validation

After removal of the base permission, one controlled invalid production
request returned:

`HTTP 400`

Response:

`{"message": "Invalid inquiry request."}`

This confirmed that the alias-specific permission alone supports the active
API Gateway request path.

## Monitoring

After cleanup:

- API 4xx alarm: OK
- API 5xx alarm: OK
- Lambda errors alarm: OK
- Lambda throttles alarm: OK
- Alarm actions: enabled

## Convergence

Post-apply Terraform returned:

`No changes. Your infrastructure matches the configuration.`

Detailed exit code:

`0`

## Final Result

**PASS**

Production now uses an alias-only API invocation permission model.

The base invoke permission is absent, the alias invoke permission remains,
`live -> 1`, Terraform state is 31 / serial 18, monitoring is healthy, and
production is fully converged.
