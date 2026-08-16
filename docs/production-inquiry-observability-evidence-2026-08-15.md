# Production Inquiry Observability Evidence — August 15, 2026

## Objective

Add production operational monitoring for the serverless portfolio inquiry workload while preserving normal application behavior.

Monitoring covers:

- AWS Lambda execution errors
- AWS Lambda throttles
- API Gateway HTTP API 5xx responses
- SNS operational notifications
- CloudWatch alarm recovery notifications

## Architecture

Normal application path:

CloudFront website
→ API Gateway HTTP API
→ Lambda
→ inquiry SNS topic
→ inquiry email subscriber

Operational monitoring path:

Lambda Errors
Lambda Throttles
API Gateway 5xx
→ CloudWatch metric alarms
→ dedicated inquiry operations SNS topic
→ confirmed operations email subscriber

The operational SNS topic is separate from the SNS topic used for valid portfolio inquiry messages.

## Terraform Module

The reusable `serverless-inquiry` module gained optional operational alarm support.

New module inputs:

- `enable_operational_alarms`
- `operational_alarm_topic_arn`

Operational alarms remain disabled by default.

The module also exports:

- Lambda error alarm ARN
- Lambda throttle alarm ARN
- API Gateway 5xx alarm ARN
- combined operational alarm ARN list

## CloudWatch Alarms

### Lambda Errors

- Namespace: `AWS/Lambda`
- Metric: `Errors`
- Statistic: `Sum`
- Period: 300 seconds
- Threshold: 1
- Evaluation periods: 1
- Datapoints to alarm: 1
- Missing data: `notBreaching`

### Lambda Throttles

- Namespace: `AWS/Lambda`
- Metric: `Throttles`
- Statistic: `Sum`
- Period: 300 seconds
- Threshold: 1
- Evaluation periods: 1
- Datapoints to alarm: 1
- Missing data: `notBreaching`

### API Gateway 5xx

- Namespace: `AWS/ApiGateway`
- Metric: `5xx`
- Statistic: `Sum`
- Period: 300 seconds
- Threshold: 1
- Evaluation periods: 1
- Datapoints to alarm: 1
- Missing data: `notBreaching`

## Terraform Testing

The serverless inquiry module test suite expanded from 14 tests to 20 tests.

Coverage includes:

- alarms disabled by default
- alarms created only when enabled
- Lambda Errors alarm configuration
- Lambda Throttles alarm configuration
- API Gateway 5xx alarm configuration
- one-event detection behavior
- missing-data behavior
- notification actions absent without an SNS ARN
- ALARM actions with an SNS ARN
- OK actions with an SNS ARN
- invalid SNS ARN rejection
- disabled alarm outputs
- enabled alarm outputs

Final local result:

`20 passed, 0 failed`

## CI Protection

A dedicated GitHub Actions workflow was added:

`Terraform Serverless Inquiry Module Tests`

Workflow gates:

1. Terraform format check
2. Terraform init without backend
3. Terraform validate
4. Terraform test

The workflow requires no AWS credentials and uses read-only repository permissions.

Verified CI run:

`31863196196`

Result:

`20 passed, 0 failed`

## Production Safety Process

Production alarm wiring was introduced with:

`enable_inquiry_operational_alarms = false`

The disabled configuration was planned before commit.

Result:

- zero AWS resource mutations
- no Terraform apply

Production enablement was then persisted only in the ignored production `terraform.tfvars`.

Enabled production tfvars SHA256:

`35410e0a57e662c73443d13836344ec6a34e5e731671768b5edc48628d833645`

## Reviewed Production Plan

Reviewed commit:

`44bc0358e2c8e0772cbc4e349831b0ca0c969842`

Saved production plan SHA256:

`e8e3d095cc3cd0138eb8dd0a342bd281c550e6a1dcca4c905894292944b57f10`

Reviewed Terraform plan:

`5 to add, 0 to change, 0 to destroy`

Exact managed resources:

1. inquiry operations SNS topic
2. inquiry operations SNS topic policy
3. Lambda Errors alarm
4. Lambda Throttles alarm
5. API Gateway 5xx alarm

## SNS Least-Privilege Policy

CloudWatch publishing is restricted to:

- service principal `cloudwatch.amazonaws.com`
- action `SNS:Publish`
- AWS account `510497448584`
- exact three inquiry alarm ARNs

The policy uses:

- `aws:SourceArn`
- `aws:SourceAccount`

## Production Apply

The exact reviewed saved plan was applied.

Result:

`5 added, 0 changed, 0 destroyed`

Production state changed from 23 to 29 objects.

The six-object state increase is explained by:

- 5 new managed resources
- 1 new `aws_caller_identity` data source

No rollback or second apply was required.

## Live Validation

Verified live:

- dedicated operations SNS topic exists
- SNS topic policy matches the least-privilege design
- Lambda Errors alarm exists
- Lambda Throttles alarm exists
- API Gateway 5xx alarm exists
- ALARM actions target the operations SNS topic
- OK actions target the operations SNS topic

Final alarm states:

- Lambda Errors: `OK`
- Lambda Throttles: `OK`
- API Gateway 5xx: `OK`

## Operations Email Subscription

A manual SNS email subscription was created outside Terraform.

Final state:

- confirmed subscriptions: 1
- pending subscriptions: 0

The email address is not stored in Terraform configuration or Git.

## Controlled Incident Drill

The Lambda Errors alarm was used for the controlled drill.

Starting state:

`OK`

CloudWatch was instructed to temporarily place the alarm into:

`ALARM`

No Lambda error was generated.

No API Gateway failure was generated.

No production application failure was induced.

CloudWatch alarm history recorded:

`OK → ALARM`

The production Lambda remained:

- State: `Active`
- LastUpdateStatus: `Successful`

The operations ALARM email arrived successfully.

## Automatic Recovery

CloudWatch reevaluated the real Lambda Errors metric.

Because no production error existed, the alarm automatically recovered:

`ALARM → OK`

Alarm history confirmed the recovery.

The recovery email also arrived successfully.

No manual recovery action was required.

## Final Production Status

- Terraform state objects: 29
- inquiry operational alarms: 3
- all three alarms: `OK`
- Lambda: `Active`
- Lambda last update: `Successful`
- operations SNS confirmed subscribers: 1
- Terraform convergence: `No changes`
- Terraform detailed exit code: 0
- repository: clean

## Result

Day 38 delivered a tested, CI-protected, least-privilege production monitoring layer for the serverless inquiry workload.

The complete operational lifecycle was validated:

healthy
→ controlled ALARM
→ alert notification
→ real metric reevaluation
→ automatic recovery
→ recovery notification

The notification system was proven without intentionally breaking the production application.
