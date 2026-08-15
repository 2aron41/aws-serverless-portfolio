# Serverless Inquiry Production Evidence — August 14, 2026

## Objective

Deploy and validate a production serverless portfolio inquiry backend using:

- Amazon API Gateway HTTP API
- AWS Lambda
- Amazon SNS
- Amazon CloudWatch Logs
- IAM least-privilege permissions
- Terraform

The workload accepts portfolio inquiries from the production CloudFront website, validates them in Lambda, publishes valid inquiries to SNS, and delivers notifications through a confirmed SNS email subscription.

## Production Request Path

CloudFront website
→ API Gateway HTTP API
→ `POST /inquiries`
→ Lambda
→ SNS topic
→ confirmed email subscriber

Production API endpoint:

`https://2v4ijd6eta.execute-api.us-east-1.amazonaws.com/inquiries`

Production Lambda:

`aws-serverless-portfolio-prod-inquiry`

Production SNS topic:

`aws-serverless-portfolio-prod-inquiries`

## API Configuration

- API type: HTTP API
- Route: `POST /inquiries`
- Authorization: `NONE`
- Integration: AWS Lambda proxy
- Payload format: `2.0`
- Integration timeout: 5000 ms
- Auto-deploy stage: `$default`

### CORS

Allowed production origin:

`https://d1wnw5kep14m5j.cloudfront.net`

Configuration:

- Allowed method: POST
- Allowed header: content-type
- Max age: 300 seconds

Live preflight verification returned HTTP 204.

### Throttling

Default route settings:

- Rate limit: 1 request/second
- Burst limit: 2
- Detailed metrics: disabled
- Data tracing: disabled

## Lambda Configuration

- Runtime: Python 3.12
- Handler: `inquiry_handler.lambda_handler`
- Memory: 128 MB
- Timeout: 5 seconds
- Architecture: x86_64
- Reserved concurrency: unreserved (`-1`)
- State after deployment: Active
- Last update status: Successful

Environment:

- `INQUIRY_TOPIC_ARN`

The handler accepts exactly:

- `name`
- `email`
- `message`

Invalid request details are not returned to callers. Invalid requests receive the generic response:

`Invalid inquiry request.`

## Logging and Privacy

CloudWatch log groups:

- `/aws/apigateway/aws-serverless-portfolio-prod-inquiry-access`
- `/aws/lambda/aws-serverless-portfolio-prod-inquiry`

Retention:

- 14 days

API access logs contain operational metadata including:

- request ID
- request time
- HTTP method
- route key
- status
- integration status
- integration latency
- response latency
- response length

The access log format does not contain request body contents.

Controlled privacy checks confirmed that the following test values were absent from inspected API Gateway and Lambda logs:

- test visitor name
- test visitor email
- test inquiry message

## Terraform Tests

Serverless inquiry module:

- 14 passed
- 0 failed

Production integration test:

- 1 passed
- 0 failed

The production integration test explicitly overrides:

`enable_inquiry = false`

and verifies the production inquiry workload can still be safely disabled.

## Production Enablement

The reusable production wiring remains disabled by default in tracked Terraform.

The real ignored production `terraform.tfvars` explicitly enables:

- `enable_inquiry = true`
- `inquiry_log_retention_days = 14`

This preserves opt-in production behavior without committing environment-specific desired state into the repository.

## Initial Production Plan

Reviewed production plan:

- 11 to add
- 0 to change
- 0 to destroy

All mutations were isolated to:

`module.serverless_inquiry`

The reviewed plan included:

- API Gateway HTTP API
- API Gateway integration
- API route
- API stage
- API access log group
- Lambda log group
- Lambda IAM role
- Lambda inline IAM policy
- Lambda function
- Lambda invoke permission
- SNS topic

## Partial Apply Incident

The initial production apply partially succeeded and then failed while Terraform attempted to configure:

`reserved_concurrent_executions = 2`

AWS account Lambda concurrency was:

- Concurrent executions: 10
- Unreserved concurrent executions: 10

AWS rejected the reservation because it would reduce the account's unreserved concurrency below the required minimum.

Before the failure, several resources had already been created successfully.

The Lambda itself was created successfully and was verified as:

- State: Active
- LastUpdateStatus: Successful
- Runtime: Python 3.12
- Memory: 128 MB
- Timeout: 5 seconds
- Correct code SHA256
- Correct SNS topic environment variable

Terraform marked the Lambda resource as tainted because the overall resource operation did not complete successfully.

Partial Terraform state contained 20 objects.

## Recovery

Terraform configuration was changed from:

`reserved_concurrent_executions = 2`

to:

`reserved_concurrent_executions = -1`

This uses normal account unreserved concurrency while API Gateway throttling remains the primary traffic-control mechanism.

Tests were updated accordingly.

Recovery commit:

`4d2e662 Use unreserved concurrency for inquiry Lambda`

After verifying the live Lambda was healthy and had no reserved concurrency configured, the Terraform taint marker was safely removed.

The Lambda remained unchanged in AWS.

## Recovery Plan

Fresh recovery plan after untaint:

- 3 to add
- 0 to change
- 0 to destroy

Exact remaining resources:

- API Gateway Lambda integration
- `POST /inquiries` route
- API Gateway Lambda invoke permission

The existing Lambda had:

- 0 planned mutations
- no replacement
- no destroy

The reviewed recovery plan was applied successfully:

- 3 added
- 0 changed
- 0 destroyed

## Final Terraform State

Final Terraform state:

- 23 objects total

Final production convergence:

`No changes. Your infrastructure matches the configuration.`

Terraform detailed exit code:

`0`

## Live API Validation

### Invalid request tests

Empty request body:

- HTTP 400

Malformed JSON:

- HTTP 400

Missing required field:

- HTTP 400

Unexpected extra field:

- HTTP 400

Invalid email:

- HTTP 400

All invalid cases returned the generic response:

`Invalid inquiry request.`

### Valid request test

Valid production inquiry:

- HTTP 202
- Response: `Inquiry received.`

The Lambda remained healthy after the requests.

## API Access Log Verification

Production access logs recorded:

- CORS OPTIONS request
- five rejected POST requests
- one accepted POST request

The accepted production request was recorded as HTTP 202.

The logs contained operational metadata without visitor request payload contents.

## SNS Publish Verification

CloudWatch metric:

`AWS/SNS NumberOfMessagesPublished`

showed:

- 1 published message

during controlled production validation.

## SNS Email Notification

The SNS topic initially had:

- Confirmed subscriptions: 0
- Pending subscriptions: 0

An email subscription was created using the AWS SNS confirmation workflow outside Terraform so that the recipient email address is not stored in Terraform configuration or Terraform state.

After confirmation:

- Confirmed subscriptions: 1
- Pending subscriptions: 0

A final controlled production inquiry was submitted.

Results:

- API returned HTTP 202
- Lambda processed the request
- SNS published the inquiry
- notification email successfully arrived
- email subject: `New portfolio inquiry`

This verifies the complete production path:

CloudFront/API client
→ API Gateway
→ Lambda validation
→ SNS
→ email delivery

## IAM Validation

API Gateway Lambda invoke permission is restricted to:

- principal: `apigateway.amazonaws.com`
- exact production HTTP API
- `$default` stage
- `POST /inquiries`

Lambda execution IAM policy remains scoped to the inquiry SNS topic and required logging capabilities.

## Static Site Regression

After the serverless deployment:

Production CloudFront:

- HTTP 200

Direct production S3:

- HTTP 403

The existing CloudFront + private S3 + OAC security model remained intact.

## Final Production Status

Production serverless inquiry backend is deployed, operational, and converged.

Verified:

- Terraform module tests
- production integration test
- API Gateway route
- Lambda proxy integration
- input validation
- generic error responses
- least-privilege IAM
- CORS restriction
- API throttling
- CloudWatch retention
- privacy-safe logging
- SNS publishing
- confirmed email subscription
- end-to-end email delivery
- Terraform zero drift
- CloudFront regression
- direct S3 access remains blocked

Day 36 production deployment is complete.
