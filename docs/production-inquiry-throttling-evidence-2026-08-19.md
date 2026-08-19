# Production Inquiry Throttling Evidence — August 19, 2026

## Objective

Harden the server-side abuse-protection configuration for the production portfolio inquiry API by making API Gateway throttling explicit, configurable, validated, and automatically tested.

The objective was not to increase or decrease the production throttle limits.

The existing live limits were preserved:

- burst limit: 2 requests
- steady-state rate limit: 1 request per second

No production AWS mutation was required.

## Existing Production Protection

The Day 40 baseline inspection verified that the production HTTP API already had server-side throttling enabled.

Live API Gateway default route settings:

    ThrottlingBurstLimit: 2
    ThrottlingRateLimit: 1.0

The production route remained:

    POST /inquiries

The route is publicly callable and does not require an API key.

The inquiry Lambda remained active and used unreserved account concurrency.

Existing operational monitoring remained healthy:

- API Gateway 5xx alarm: OK
- Lambda Errors alarm: OK
- Lambda Throttles alarm: OK

Terraform was fully converged before Day 40 changes.

## Layered Protection

The inquiry workload now has two complementary protections.

### Frontend protection

Day 39 added a 30-second in-memory cooldown.

This reduces accidental rapid duplicate submissions in the browser.

### Server-side protection

API Gateway enforces request throttling independently of the frontend:

- burst limit: 2
- rate limit: 1 request per second

The server-side control cannot be bypassed simply by refreshing the browser or calling the API directly.

The two layers serve different purposes:

    browser duplicate prevention
    +
    API Gateway request throttling

## Test-First Development

Day 40 used a red/green workflow.

### RED phase

A new Terraform test requested custom throttling:

    api_throttling_burst_limit = 1
    api_throttling_rate_limit  = 0.5

Before implementation, Terraform warned that the throttle variables were undeclared.

The test also proved that the stage remained hard-coded to:

    burst = 2
    rate = 1

Result:

    Failure! 20 passed, 1 failed.

The failure occurred for the expected reason.

### GREEN phase

Two reusable module variables were added:

    api_throttling_burst_limit
    api_throttling_rate_limit

Safe defaults preserve the existing production behavior:

    api_throttling_burst_limit = 2
    api_throttling_rate_limit  = 1

The API Gateway stage now consumes those variables instead of hard-coded values.

## Input Validation

The burst limit requires:

- value greater than or equal to 1
- whole-number value

The rate limit requires:

- value greater than 0

Negative test coverage verifies Terraform rejects:

- burst limit of 0
- fractional burst limit of 1.5
- rate limit of 0

## Terraform Test Coverage

The serverless inquiry module test suite expanded from 20 tests to 24 tests.

New Day 40 tests:

- `http_api_custom_throttling`
- `reject_zero_api_throttling_burst_limit`
- `reject_fractional_api_throttling_burst_limit`
- `reject_zero_api_throttling_rate_limit`

Final local result:

    Success! 24 passed, 0 failed.

## Reusable Module Commit

Commit:

    74aba16d4aa46c56d24175bd51569126c3478eaa

Commit message:

    Make inquiry API throttling configurable

Files changed:

- `infra/modules/serverless-inquiry/main.tf`
- `infra/modules/serverless-inquiry/variables.tf`
- `infra/modules/serverless-inquiry/tests/basic.tftest.hcl`

## Module CI Verification

Dedicated workflow:

    Terraform Serverless Inquiry Module Tests

CI run:

    32290383480

Verified gates:

- Terraform format check
- Terraform init without backend
- Terraform validate
- Terraform test

Result:

    Success! 24 passed, 0 failed.

CI conclusion:

    success

## Production Wiring

The production Terraform root now exposes explicit throttle settings:

    inquiry_api_throttling_burst_limit
    inquiry_api_throttling_rate_limit

Production defaults:

    burst = 2
    rate = 1

The variables are passed explicitly into the reusable serverless inquiry module.

The tracked `terraform.tfvars.example` documents the values.

The real production `terraform.tfvars` remained ignored, untracked, and unchanged.

## Production Zero-Change Plan

Before committing production wiring, a fresh saved production plan was created.

Terraform reported:

    No changes. Your infrastructure matches the configuration.

Detailed exit code:

    0

Saved plan resource mutations:

    0

Therefore, the explicit production wiring preserved the existing live infrastructure exactly.

## Production Wiring Commit

Commit:

    dec95c3a52d6b062b3986f98a9c8d99c9999cb5a

Commit message:

    Wire production inquiry throttling

Files changed:

- `infra/environments/prod/main.tf`
- `infra/environments/prod/variables.tf`
- `infra/environments/prod/terraform.tfvars.example`

No Terraform apply was required.

## Final CI Verification

Website validation CI run:

    32290897525

Conclusion:

    success

The reusable serverless module CI baseline also remained successful:

    32290383480

## Final Production Verification

Fresh Terraform convergence check:

    No changes. Your infrastructure matches the configuration.

Terraform detailed exit code:

    0

Live API Gateway throttling:

    Burst: 2
    Rate: 1.0

Terraform state objects:

    29

No production resource creation, modification, or destruction occurred.

## Day 40 Result

Day 40 converted previously hard-coded API Gateway throttling into an explicit, reusable, validated Terraform configuration while preserving the current production behavior.

Final state:

- frontend 30-second duplicate cooldown remains active
- API Gateway server-side throttling remains active
- burst limit remains 2
- rate limit remains 1 request per second
- throttling values are configurable
- invalid configurations are rejected
- 24 Terraform tests pass
- dedicated module CI passes
- production root explicitly declares throttle intent
- production Terraform is fully converged
- state remains at 29 objects
- no AWS apply was required

## Security Boundary

API Gateway throttling limits request rate but is not complete abuse prevention.

It does not provide:

- identity-aware rate limiting
- CAPTCHA or bot challenges
- persistent per-user cooldowns
- request deduplication
- application-level idempotency

Those controls can be considered later if the portfolio receives enough public traffic to justify the additional complexity.
