# Production Inquiry Lambda Rollback Readiness Evidence

**Date:** August 24, 2026
**Environment:** Production
**Region:** us-east-1

## Objective

Audit the production inquiry Lambda rollback architecture without changing
production, determine whether a genuine rollback target currently exists,
and update the active incident runbook to match the deployed architecture.

## Starting Source

Day 48 began from the completed Day 47 documentation commit:

`3caaa4add4415ea5cb2dc794cb1c4868bbe64e26`

The repository was clean and synchronized with `origin/main`.

## Authentication Interruption

The first audit attempt encountered an expired AWS CLI login session.

AWS and Terraform reads failed because credentials were unavailable.

An empty redirected `terraform state list` result temporarily produced a
misleading shell count of `0`.

That value was rejected because the Terraform command itself had failed.

After reauthentication, the production identity was verified as:

- account: `510497448584`
- ARN: `arn:aws:iam::510497448584:user/aaron-admin`

No production change occurred during the expired-session failure.

## Authoritative Production Baseline

After authentication was restored:

- Terraform lineage:
  `ca7b1441-16c0-360d-89f7-22da6de017fe`
- Terraform serial: `18`
- Terraform resource count: `31`
- API integration:
  Lambda `live` alias
- API route target:
  `integrations/4ugv6de`
- `live -> 1`

## Lambda Version Inventory

Lambda versions returned:

- `$LATEST`
- version `1`

Both had code SHA256:

`x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`

Numbered Lambda versions:

`1`

Therefore version `1` is the only immutable numbered Lambda version.

## Rollback Readiness Finding

The production architecture now has a real alias-based rollback mechanism:

`API Gateway -> live alias -> numbered Lambda version`

Terraform supports an explicit alias target through:

`inquiry_lambda_alias_version`

The module also contains tests for:

- explicit rollback version override
- rejection of invalid alias versions

However, no older numbered Lambda version currently exists.

Therefore:

- rollback mechanism available: YES
- previous immutable rollback target available: NO
- real rollback rehearsal currently possible: NO

`$LATEST` is not treated as an immutable rollback version.

## Permission Model

The active alias permission is:

`AllowInquiryApiGatewayInvokeLiveAlias`

It allows:

`lambda:InvokeFunction`

for:

`apigateway.amazonaws.com`

and is scoped to:

`arn:aws:execute-api:us-east-1:510497448584:2v4ijd6eta/$default/POST/inquiries`

The unqualified Lambda resource policy is absent.

Terraform state contains only:

`module.serverless_inquiry.aws_lambda_permission.inquiry_api_alias[0]`

The redundant base permission remains removed.

## Regression Validation

Serverless inquiry module:

`Success! 32 passed, 0 failed.`

Production Terraform test:

`Success! 1 passed, 0 failed.`

Terraform validation:

`Success! The configuration is valid.`

## Terraform Convergence

Production plan returned:

`No changes. Your infrastructure matches the configuration.`

Detailed exit code:

`0`

No Terraform apply was performed.

## Monitoring

All four inquiry operational alarms were healthy:

- API 4xx: OK
- API 5xx: OK
- Lambda errors: OK
- Lambda throttles: OK

Alarm actions were enabled.

## Production Activity

During the Day 48 readiness audit:

- production requests generated: `0`
- Terraform apply operations: `0`
- intentional AWS configuration changes: `0`

## Runbook Finding

The active incident runbook still described the pre-alias architecture,
including statements that production used `$LATEST`, published no numbered
versions, and had no Lambda aliases.

Those statements were no longer accurate after Days 45-47.

Historical evidence files were left unchanged because they accurately describe
the architecture at the time they were written.

## Runbook Update

Updated:

`docs/inquiry-incident-runbook.md`

The active runbook now documents:

- the `live` alias architecture
- `inquiry_lambda_alias_version`
- Terraform-controlled alias rollback
- the requirement to identify a known-good numbered version
- the current lack of an older rollback target
- prohibition on manufacturing a rollback target
- prohibition on manually repointing `live` as the normal procedure
- prohibition on manual Lambda code updates as the normal recovery path
- reviewed saved-plan and CI gates for future rollback

Runbook commit:

`11ed9aa59c07e39c7a1806b57a480eda96f3ba23`

Commit message:

`Update inquiry Lambda rollback runbook`

The commit changed exactly one file.

No Terraform or AWS change accompanied the runbook commit.

## Final Day 48 Baseline

- Terraform resources: `31`
- Terraform serial: `18`
- API Gateway -> `live`
- `live -> 1`
- numbered Lambda versions: `1`
- base invoke permission: absent
- alias invoke permission: present
- module tests: `32/32`
- production test: `1/1`
- Terraform validation: PASS
- Terraform convergence: No changes
- alarms: `4/4 OK`
- production requests: `0`
- Terraform apply: NO
- AWS configuration changes from audit/runbook work: `0`
- real rollback candidate: NO

## Conclusion

**PASS**

The alias-based rollback architecture is deployed and correctly represented
in Terraform and the active runbook.

The remaining readiness gap is not the rollback mechanism itself. The gap is
the absence of an older known-good immutable Lambda version.

A future rollback rehearsal must wait until at least two legitimate reviewed
numbered versions exist.
