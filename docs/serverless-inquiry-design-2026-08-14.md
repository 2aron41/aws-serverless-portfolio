# Serverless Inquiry Design — August 14, 2026

## Day 36

## Business Problem

Portfolio visitors currently have no structured way to send an inquiry directly from the website.

The desired outcome is a small, secure, low-cost contact workflow that delivers valid visitor inquiries to the portfolio owner.

## Requirements

- Public portfolio visitors can submit an inquiry.
- No AWS credentials are exposed to browser code.
- Requests are treated as untrusted input.
- Invalid submissions fail safely.
- Production S3 remains private.
- The backend uses least-privilege IAM.
- Basic abuse and cost controls are included.
- Visitor message bodies are not written to normal application logs.
- Infrastructure remains serverless and pay-per-use.

## Constraints

- Expected traffic is very low.
- No always-on compute is justified.
- No database requirement currently exists.
- No complex disaster-recovery architecture is justified.
- Keep the number of AWS services small.

## Selected Architecture

```text
Portfolio browser
       |
       | POST /inquiries
       v
API Gateway HTTP API
       |
       v
Python Lambda
       |
       v
Dedicated SNS inquiry topic
       |
       v
Owner email notification
```

## API Decision

Use API Gateway HTTP API rather than a Lambda Function URL.

Reasons:

- explicit API routing;
- CORS configuration;
- API access logging capability;
- API-level throttling;
- cleaner separation between public API and compute;
- better foundation if the portfolio API grows later.

A Lambda Function URL would be simpler and slightly cheaper, but the API-management controls are worth the small additional complexity for a public contact endpoint.

## Notification Decision

Use a dedicated SNS topic for owner notification.

Do not reuse the existing CloudFront alert topic because infrastructure alarms and visitor inquiries are separate business concerns.

SES is deferred until requirements exist for branded transactional email, visitor acknowledgements, or custom email-sending behavior.

## Storage Decision

Do not add DynamoDB on Day 36.

The immediate business requirement is notification delivery, not inquiry history, analytics, status tracking, or CRM behavior.

Persistence can be added later if one of those requirements becomes real.

## Security Controls

- expose only POST /inquiries;
- restrict browser CORS to the portfolio origin;
- validate all Lambda input;
- enforce field-length limits;
- reject unsupported request shapes;
- do not log inquiry message bodies;
- grant Lambda sns:Publish only to the dedicated inquiry topic;
- configure API throttling;
- return generic server errors without stack traces;
- keep AWS credentials out of frontend code;
- fail safely when notification publishing fails.

## Initial API Contract

Request:

```json
{
  "name": "Visitor Name",
  "email": "visitor@example.com",
  "message": "Inquiry text"
}
```

Initial validation limits:

```text
name:    2-100 characters
email:   3-254 characters
message: 10-2000 characters
```

Successful requests should return a success response only after SNS accepts the publish request.

## Terraform Design

Create a separate reusable serverless-inquiry module instead of placing application backend resources inside the existing static-site module.

The module should be disabled by default until explicitly enabled by an environment.

Production apply is prohibited until local tests, Terraform validation, CI, production plan review, and safety checks pass.

## Day 36 Initial Scope

```text
API Gateway HTTP API: SELECTED
Lambda:               SELECTED
SNS notification:     SELECTED
DynamoDB:             DEFERRED
SES:                  DEFERRED
REST API:             NOT JUSTIFIED
Function URL:         NOT SELECTED
AWS changes so far:   NONE
```
