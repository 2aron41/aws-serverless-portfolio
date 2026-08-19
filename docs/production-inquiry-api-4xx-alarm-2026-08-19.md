# Production Inquiry API 4xx Operational Alarm — August 19, 2026

## Purpose

Day 42 added production monitoring for sustained abnormal client-error
traffic against the serverless inquiry API.

The new CloudWatch alarm monitors the API Gateway `4xx` metric and extends
the existing inquiry operational monitoring stack without replacing or
destroying existing resources.

## Starting State

Before Day 42:

- production Terraform state contained 29 objects
- inquiry operational monitoring contained three alarms:
  - Lambda Errors
  - Lambda Throttles
  - API Gateway 5xx
- the operations SNS topic policy permitted exactly those three alarm ARNs
- production Terraform was converged

## Module Implementation

Added:

- configurable `api_4xx_alarm_threshold`
- API Gateway 4xx CloudWatch alarm
- dedicated `api_4xx_alarm_arn` output
- API 4xx alarm in the combined `operational_alarm_arns` output
- ALARM notification coverage
- OK notification coverage
- dedicated Terraform tests for the 4xx alarm
- configurable-threshold test coverage

The module test suite increased from 24 to 26 Terraform test runs.

Final local result:

`Success! 26 passed, 0 failed.`

## Alarm Configuration

Production alarm:

`aws-serverless-portfolio-prod-inquiry-api-4xx`

Configuration:

- Namespace: `AWS/ApiGateway`
- Metric: `4xx`
- Statistic: `Sum`
- Threshold: `20`
- Period: `300` seconds
- Evaluation periods: `2`
- Datapoints to alarm: `2`
- Comparison: `GreaterThanOrEqualToThreshold`
- Missing data: `notBreaching`
- Dimension: production inquiry API ID
- ALARM action: production inquiry operations SNS topic
- OK action: production inquiry operations SNS topic

This requires the configured threshold to be met for two consecutive
five-minute evaluation periods before the alarm enters ALARM.

## CI Verification

Dedicated serverless inquiry module CI was verified against commit:

`abbcda90a9cb935e126c255211c0d37b6a079658`

GitHub Actions run:

`32294381417`

Result:

- Terraform format check: pass
- Terraform init without backend: pass
- Terraform validate: pass
- Terraform test: pass
- Terraform tests: 26 passed, 0 failed
- workflow conclusion: success

## Production Impact Review

The reviewed production plan contained exactly:

- 1 resource to add
- 1 resource to change in place
- 0 resources to destroy

Planned changes:

1. Create the API Gateway 4xx CloudWatch alarm.
2. Update the existing inquiry operations SNS topic policy in place.

No replacement or destructive actions were present.

## Production Apply

The exact reviewed saved Terraform plan was applied.

Apply result:

`Resources: 1 added, 1 changed, 0 destroyed.`

Created:

`module.serverless_inquiry.aws_cloudwatch_metric_alarm.inquiry_api_4xx[0]`

Updated in place:

`aws_sns_topic_policy.inquiry_operations[0]`

No replan was performed during the apply step.

## SNS Policy Verification

After apply, the inquiry operations SNS policy permits exactly these four
CloudWatch alarm ARNs:

1. Lambda Errors
2. Lambda Throttles
3. API Gateway 5xx
4. API Gateway 4xx

The policy continues to restrict CloudWatch publishing using:

`aws:SourceAccount = 510497448584`

The new API 4xx alarm has both its ALARM and OK actions configured to use
the production inquiry operations SNS topic.

## Post-Apply Alarm Health

Final operational alarm state:

- API Gateway 4xx: `OK`
- API Gateway 5xx: `OK`
- Lambda Errors: `OK`
- Lambda Throttles: `OK`

The new 4xx alarm initially entered `INSUFFICIENT_DATA` immediately after
creation and subsequently transitioned to `OK` without requiring generated
traffic.

No additional requests were sent during post-apply verification.

## Terraform Verification

Production state increased from:

`29 -> 30 objects`

The increase corresponds to the new API Gateway 4xx CloudWatch alarm.

Final Terraform convergence:

`No changes. Your infrastructure matches the configuration.`

Terraform detailed exit code:

`0`

## Safety Controls

Day 42 preserved the following controls:

- exact AWS account verification before production apply
- exact CI-approved Git commit verification
- saved-plan SHA256 verification
- production tfvars SHA256 verification
- exact saved-plan application
- no replan during apply
- no resource replacement
- no resource destruction
- exact SNS SourceArn restrictions
- SourceAccount restriction preserved
- post-apply Terraform convergence verification
- clean Git repository verification

## Final Result

Day 42 successfully extended production inquiry observability with an
API Gateway 4xx operational alarm.

Final state:

- operational alarms: 4
- all four alarms: OK
- Terraform state objects: 30
- Terraform: converged
- module tests: 26 passed
- dedicated CI: success
- repository: clean and synchronized
- destructive changes: 0

The production inquiry stack can now detect sustained abnormal client-error
traffic in addition to Lambda errors, Lambda throttling, and API Gateway
5xx failures.
