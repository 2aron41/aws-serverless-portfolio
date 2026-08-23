# Production Inquiry Lambda Alias — Phase B Traffic Migration Evidence

**Date:** August 23, 2026
**Environment:** Production
**Region:** us-east-1
**AWS account:** 510497448584

## Objective

Complete the second phase of the production inquiry Lambda rollback
architecture by routing the existing API Gateway integration through the
Terraform-managed `live` Lambda alias.

Phase A had already created:

- Numbered Lambda version publication.
- Lambda version `1`.
- Stable alias `live -> 1`.
- Alias-specific API Gateway invoke permission.
- Terraform rollback version override support.

Phase B changed only the API Gateway integration traffic target.

## Test-First Development

The Phase B routing behavior was developed test-first.

Initial module regression baseline:

`32 passed, 0 failed`

A RED test changed the alias-enabled routing expectation from the base Lambda
invoke ARN to the `live` alias invoke ARN.

Because the alias `invoke_arn` is computed during planning, the test added a
targeted plan-time Terraform override for the alias invoke ARN.

The precise RED result was:

`31 passed, 1 failed`

The single expected failing run was:

`lambda_version_and_live_alias_when_enabled`

The GREEN implementation changed only the integration expression:

```hcl
integration_uri = (
  var.enable_lambda_alias
  ? aws_lambda_alias.inquiry_live[0].invoke_arn
  : aws_lambda_function.inquiry[0].invoke_arn
)
```

After the implementation:

`32 passed, 0 failed`

The alias-disabled/default behavior continues to use the base Lambda invoke ARN.

## Source Commit

Phase B routing commit:

`58f9977bb938d838f9374ac93b727e273da04802`

Commit message:

`Route inquiry API through live Lambda alias`

Committed files:

- `infra/modules/serverless-inquiry/main.tf`
- `infra/modules/serverless-inquiry/tests/basic.tftest.hcl`

## Continuous Integration

Serverless module CI run:

`32659143146`

Result:

`success`

Production Terraform CI run:

`32659143151`

Result:

`success`

Both runs executed against the exact Phase B routing commit.

## Reviewed Saved Plan

Applied saved plan:

`/tmp/day46-phase-b-post-ci.tfplan`

Saved-plan SHA256:

`58e1df4ded9299c2255d3dc3c9300f67ded330fbc50d3cddd5894e565ea33821`

Production terraform.tfvars SHA256:

`2c567809f8d8fdf7b99fcc6250d62e4549a4775aef6a15929c9cdbd87a111519`

The saved plan was generated only after the Phase B commit and both required
CI workflows had succeeded.

The exact saved plan was applied without regeneration.

## Terraform Mutation

The saved plan contained exactly one managed-resource change:

`module.serverless_inquiry.aws_apigatewayv2_integration.inquiry[0]`

Action:

`update in-place`

Plan summary:

`0 to add, 1 to change, 0 to destroy`

No resource replacement occurred.

The only changed integration field was:

`integration_uri`

## Routing Transition

Before Phase B:

`arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:510497448584:function:aws-serverless-portfolio-prod-inquiry/invocations`

After Phase B:

`arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:510497448584:function:aws-serverless-portfolio-prod-inquiry:live/invocations`

API integration ID remained:

`4ugv6de`

API route ID remained:

`5q5uwbq`

The route target remained:

`integrations/4ugv6de`

Therefore the existing API route and integration resource were preserved; only
the Lambda invocation target changed.

## Lambda Recovery State

Lambda function:

`aws-serverless-portfolio-prod-inquiry`

Current numbered versions:

- `1`

Current alias:

`live -> 1`

Reviewed Lambda code SHA256:

`x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`

Both `$LATEST` and version `1` retained the reviewed code SHA throughout
Phase B.

Phase B caused:

- Lambda code changes: 0.
- Lambda version changes: 0.
- Alias target changes: 0.

## Invoke Permissions

The original base-function permission remains present:

`AllowInquiryApiGatewayInvoke`

The alias-specific permission remains present:

`AllowInquiryApiGatewayInvokeLiveAlias`

Both permissions remain constrained to:

`arn:aws:execute-api:us-east-1:510497448584:2v4ijd6eta/$default/POST/inquiries`

Keeping the original base permission during the routing migration was
intentional.

Its removal is deferred to a separate reviewed cleanup change.

## Terraform State

State lineage:

`ca7b1441-16c0-360d-89f7-22da6de017fe`

State serial before Phase B apply:

`16`

State serial after Phase B apply:

`17`

State object count:

`32`

The state count remained unchanged because the existing API integration was
updated in place.

## Controlled Production Validation

After routing API Gateway through `live`, one controlled POST request was sent
to the production inquiry endpoint using an intentionally invalid empty JSON
payload.

Expected response:

`HTTP 400`

Observed response:

`HTTP 400`

Observed body:

`{"message": "Invalid inquiry request."}`

This validated the alias-routed production request path without creating a
valid inquiry or SNS inquiry publication.

Controlled production requests generated by this Phase B verification:

`1`

## Monitoring

After the routing change and controlled validation request, all four inquiry
operational alarms remained:

`OK`

with alarm actions enabled.

Verified alarms:

- API Gateway 4xx.
- API Gateway 5xx.
- Lambda errors.
- Lambda throttles.

## Post-Apply Convergence

A fresh Terraform production plan after the Phase B apply returned:

`No changes. Your infrastructure matches the configuration.`

Detailed exit code:

`0`

This confirms Terraform state, configuration, and the live AWS infrastructure
converged after the routing migration.

## Rollback Capability

Production API traffic now traverses:

`API Gateway -> live alias -> Lambda version 1`

This activates the alias-based rollback architecture.

A reviewed Terraform rollback can change the `live` alias target to an older
numbered Lambda version without changing the API Gateway integration.

The configured rollback model remains:

- `lambda_alias_version = null`: follow the newly published reviewed version.
- Explicit numbered value: pin `live` to that reviewed Lambda version.

Manual alias edits remain Terraform drift and should not be the normal rollback
method.

## Deferred Permission Cleanup

The unqualified base Lambda invoke permission is now redundant for the current
alias-routed API traffic path.

It should **not** be removed as part of this already-completed migration.

Any removal should be handled as a separate change with its own:

- Test-first change.
- Commit.
- CI verification.
- Production plan.
- Saved-plan review.
- Controlled apply.
- Post-apply validation.

## Phase B Result

**PASS**

Production API Gateway now invokes the stable `live` Lambda alias.

The alias remains pinned to Lambda version `1`, the Lambda code did not
change, both invoke permissions remain available, all four operational alarms
are healthy, and Terraform is fully converged.
