# Production Inquiry Throttle Drill Evidence — August 19, 2026

## Objective

Safely exercise the production inquiry API under a bounded amount of concurrent traffic and verify:

- invalid requests cannot generate inquiry notifications
- API Gateway access logs capture request behavior
- CloudWatch metrics account for the traffic
- Lambda remains healthy
- production alarms remain healthy
- Terraform remains converged
- no production configuration changes are required

The drill deliberately used invalid request bodies so no real portfolio inquiries would be created.

## Starting Production State

Production began the drill healthy.

API Gateway default route throttling:

    Burst: 2
    Rate: 1.0

Production route:

    POST /inquiries

Lambda:

    aws-serverless-portfolio-prod-inquiry

Lambda state:

    Active

Last update status:

    Successful

Operational alarms:

- API Gateway 5xx: OK
- Lambda Errors: OK
- Lambda Throttles: OK

Terraform state objects:

    29

Terraform:

    No changes

Repository:

    clean and synchronized

## Validation Safety Inspection

The production Lambda source was inspected before sending test traffic.

Request processing order:

1. confirm HTTP method
2. parse request
3. validate request body
4. return HTTP 400 when validation fails
5. call `publish_inquiry()` only after successful validation

The SNS publish path therefore occurs only after a request passes validation.

The selected test payload was:

    {}

This is valid JSON but does not contain exactly:

- name
- email
- message

The handler therefore rejects it before SNS publication.

Expected response:

    HTTP 400
    {"message": "Invalid inquiry request."}

## Single Safety Probe

One invalid request was sent before any concurrent test.

Payload:

    {}

Observed result:

    HTTP 400
    {"message": "Invalid inquiry request."}

The response exactly matched the expected Lambda validation path.

Valid inquiry submitted:

    no

## First Concurrent Burst

A controlled burst of 6 invalid requests was sent.

Observed:

    HTTP 400: 6
    HTTP 429: 0
    Other: 0

All six response bodies were:

    {"message": "Invalid inquiry request."}

No valid inquiries were submitted.

The first burst did not produce an HTTP 429 response.

## Bounded Second Burst

A second and final bounded test sent 20 concurrent invalid requests.

Observed:

    HTTP 400: 20
    HTTP 429: 0
    Other: 0

All twenty requests returned:

    {"message": "Invalid inquiry request."}

The test was intentionally stopped after this bounded attempt rather than increasing production load simply to force a 429 response.

## Total Controlled Traffic

Day 41 generated:

    1 single validation probe
    6-request concurrent burst
    20-request concurrent burst
    -----------------------------
    27 controlled invalid requests

Valid inquiry payloads:

    0

Observed HTTP 429 responses:

    0

Unexpected HTTP responses:

    0

## API Gateway Access Log Evidence

CloudWatch access logs eventually delivered all 20 events from the final bounded burst.

Each event recorded:

    status = 400
    routeKey = POST /inquiries
    integrationStatus = 200

All 20 final-burst requests reached the Lambda integration successfully and were rejected by application validation.

The access log remained privacy-safe and contained metadata rather than inquiry bodies.

## API Gateway CloudWatch Metrics

The drill window showed:

### 19:14 UTC

    Count: 1
    4xx:   1
    5xx:   0

This corresponds to the single safety probe.

### 19:15 UTC

    Count: 6
    4xx:   6
    5xx:   0

This corresponds to the first concurrent burst.

### 19:17 UTC

    Count: 20
    4xx:   20
    5xx:   0

This corresponds to the final bounded concurrent burst.

Total API Gateway evidence:

    Requests: 27
    4xx:      27
    5xx:      0

## Lambda CloudWatch Metrics

The same drill window showed:

### Invocations

    1 + 6 + 20 = 27

### Errors

    0

### Lambda Throttles

    0

Therefore every controlled request reached Lambda, Lambda executed normally, and request validation returned the intended application-level 400 response.

## SNS Verification

CloudWatch metric:

    AWS/SNS
    NumberOfMessagesPublished

Topic:

    aws-serverless-portfolio-prod-inquiries

Messages published during the complete drill window:

    0

This independently verifies that the invalid traffic did not generate inquiry notifications.

## Alarm Health

After the drill:

- `aws-serverless-portfolio-prod-inquiry-api-5xx` — OK
- `aws-serverless-portfolio-prod-inquiry-lambda-errors` — OK
- `aws-serverless-portfolio-prod-inquiry-lambda-throttles` — OK

No production incident was created.

## Lambda Health

After all controlled traffic:

    State: Active
    LastUpdateStatus: Successful

## Terraform Verification

Final production Terraform plan:

    No changes. Your infrastructure matches the configuration.

Detailed exit code:

    0

Production state objects:

    29

AWS configuration changes during Day 41:

    0

Terraform apply:

    not performed

## Throttling Result

The production API continued to report configured throttling:

    Burst: 2
    Rate: 1.0

However, the bounded live production drill did not observe an HTTP 429 response.

This result is recorded as observed rather than altered to fit an expected outcome.

No additional production load was generated after the 20-request bounded test.

Day 41 therefore validated the surrounding production behavior and observability without claiming a 429 that was not observed.

## Day 41 Result

The controlled production drill verified:

- 27 controlled invalid requests
- 27 API Gateway requests accounted for
- 27 API Gateway 4xx responses
- 27 Lambda invocations
- 0 API Gateway 5xx responses
- 0 Lambda errors
- 0 Lambda throttles
- 0 inquiry SNS publications
- 0 valid inquiry submissions
- 0 unexpected HTTP responses
- 0 observed HTTP 429 responses
- Lambda remained healthy
- all inquiry operational alarms remained OK
- Terraform remained fully converged
- Terraform state remained at 29 objects
- repository remained clean
- no AWS configuration changes occurred

The drill demonstrated safe production testing, full request accounting, privacy-safe logging, and correct validation isolation without deliberately creating a production failure.
