# Production Inquiry Lambda Alias — Phase A Evidence

**Date:** August 23, 2026
**Environment:** Production
**Region:** us-east-1
**AWS account:** 510497448584

## Objective

Establish the rollback foundation for the production inquiry Lambda without
changing the production API traffic path.

Phase A introduced:

- Lambda numbered-version publishing.
- A stable Lambda alias named `live`.
- An alias-specific API Gateway invoke permission.
- A Terraform-controlled rollback version override.

Phase A intentionally did **not** route API Gateway through the alias.

## Source and CI Evidence

Production wiring commit:

`a42bb21893cec2ab3ce7b7e5842202bd989d31fe`

Production Terraform CI run:

`32657277996`

CI result:

`success`

Module regression suite before the wiring commit:

`32 passed, 0 failed`

Production Terraform test:

`1 passed, 0 failed`

Production configuration validation:

`passed`

## Reviewed Apply Artifact

Applied saved plan:

`/tmp/day45-phase-a-post-ci.tfplan`

Saved-plan SHA256:

`4b53c302380d597bff9aaf52cc9e5da248d3ea1ef5cbd0c4c945931b88e968c6`

Production terraform.tfvars SHA256:

`2c567809f8d8fdf7b99fcc6250d62e4549a4775aef6a15929c9cdbd87a111519`

The exact saved plan was applied without regeneration.

Reviewed mutation set:

- Create `aws_lambda_alias.inquiry_live[0]`.
- Update `aws_lambda_function.inquiry[0]` in place.
- Create `aws_lambda_permission.inquiry_api_alias[0]`.

Plan result:

`2 to add, 1 to change, 0 to destroy`

No resource replacement occurred.

## Lambda Evidence

Lambda function:

`aws-serverless-portfolio-prod-inquiry`

Lambda state:

`Active`

Last update status:

`Successful`

Reviewed Lambda code SHA256:

`x+bnbk+wu+p+PF2XZA52ItpS7fo2/dU/yjEdKqwY6rk=`

Before Phase A:

- Only `$LATEST` existed.
- No aliases existed.
- Terraform had `publish = false`.

After Phase A:

- Terraform has version publication enabled.
- Numbered version `1` exists.
- Version `1` contains the reviewed Lambda code SHA.
- Alias `live` targets version `1`.

Current alias mapping:

`live -> 1`

## API Gateway Permission Evidence

The original unqualified invoke permission remains present:

`AllowInquiryApiGatewayInvoke`

The new alias-specific invoke permission exists:

`AllowInquiryApiGatewayInvokeLiveAlias`

Both are constrained to:

`arn:aws:execute-api:us-east-1:510497448584:2v4ijd6eta/$default/POST/inquiries`

## Production Traffic Boundary

Production API Gateway integration ID:

`4ugv6de`

Current integration URI:

`arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:510497448584:function:aws-serverless-portfolio-prod-inquiry/invocations`

This URI remains **unqualified**.

Therefore Phase A did not route production traffic through `live`.

Changing the alias target by itself would not currently change production API
traffic because API Gateway still invokes the base Lambda function.

## Terraform State Evidence

State lineage:

`ca7b1441-16c0-360d-89f7-22da6de017fe`

State serial after Phase A:

`16`

State object count after Phase A:

`32`

New managed state objects:

- `module.serverless_inquiry.aws_lambda_alias.inquiry_live[0]`
- `module.serverless_inquiry.aws_lambda_permission.inquiry_api_alias[0]`

State lineage was preserved and the serial advanced normally.

## Monitoring Evidence

The four inquiry operational alarms remained healthy after Phase A:

- API Gateway 4xx alarm — OK.
- API Gateway 5xx alarm — OK.
- Lambda errors alarm — OK.
- Lambda throttles alarm — OK.

Alarm actions remained enabled.

## Post-Apply Convergence

A fresh production Terraform plan after the apply returned:

`No changes. Your infrastructure matches the configuration.`

This confirms Terraform and the live production configuration converged after
Phase A.

## Phase B Boundary

Phase B should be a separate reviewed production change.

### Goal

Route API Gateway through the stable Lambda alias:

`live`

### Intended Terraform Change

The expected Phase B mutation should be limited to the inquiry API Gateway
integration URI.

The integration should change from the unqualified function invocation:

`arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:510497448584:function:aws-serverless-portfolio-prod-inquiry/invocations`

to an alias-qualified invocation ending in:

`:function:aws-serverless-portfolio-prod-inquiry:live/invocations`

### Intended Safety Boundary

Phase B should:

- Keep `live -> 1` unchanged during the routing migration.
- Keep the alias-specific API Gateway permission.
- Keep the original unqualified permission temporarily.
- Change only the API Gateway integration traffic target.
- Avoid Lambda code/configuration changes.
- Avoid Lambda alias target changes.
- Avoid alarm changes.
- Avoid destruction and resource replacement.

Expected state count should remain approximately `32` because the API
integration already exists and should be updated in place.

### Phase B Verification Requirements

Before apply:

- Clean and synchronized repository.
- Exact reviewed commit.
- Successful production Terraform CI.
- Production state count 32.
- Terraform convergence before the proposed routing change.
- Lambda version 1 healthy.
- `live -> 1`.
- Version 1 and `$LATEST` reviewed code SHA still match.
- Four inquiry alarms OK.
- Existing API integration confirmed unqualified.

After apply:

- API Gateway integration must invoke `live`.
- `live` must still target version 1.
- Lambda code SHA must remain unchanged.
- Both invoke permissions should still exist during initial verification.
- State count should remain 32.
- All four alarms should remain healthy.
- Production inquiry endpoint should receive a controlled validation request.
- Terraform must converge to explicit `No changes`.

### Deferred Cleanup

Removal of the now-redundant unqualified Lambda invoke permission should **not**
be combined with Phase B.

That cleanup should be considered only after the alias-routed production path
has been proven healthy.

## Phase A Result

**PASS**

The production inquiry Lambda now has a Terraform-managed numbered version and
stable `live` alias suitable for future rollback control.

Production traffic has not yet been migrated to that alias.
