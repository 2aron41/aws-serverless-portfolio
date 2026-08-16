# Production Inquiry Incident Runbook

## Purpose

This runbook covers incidents affecting the production serverless portfolio inquiry service.

Production components:

- Amazon API Gateway HTTP API
- AWS Lambda
- Amazon SNS inquiry topic
- Amazon SNS operations topic
- Amazon CloudWatch Logs
- Amazon CloudWatch metric alarms

Operational alarms:

- `aws-serverless-portfolio-prod-inquiry-lambda-errors`
- `aws-serverless-portfolio-prod-inquiry-lambda-throttles`
- `aws-serverless-portfolio-prod-inquiry-api-5xx`

## First Response

When an operations alert arrives:

1. Identify the alarm.
2. Confirm its current state.
3. Review the state reason.
4. Review recent alarm history.
5. Inspect the affected service.
6. Inspect relevant logs or metrics.
7. Do not immediately change production infrastructure.
8. Determine whether the incident is active, recovered, or a controlled test.

Check all inquiry alarms:

    aws cloudwatch describe-alarms \
      --region us-east-1 \
      --alarm-name-prefix aws-serverless-portfolio-prod-inquiry-

## Alarm History

Review state transitions:

    aws cloudwatch describe-alarm-history \
      --region us-east-1 \
      --alarm-name <ALARM_NAME> \
      --history-item-type StateUpdate \
      --max-records 20

Record:

- when the alarm entered `ALARM`
- when it returned to `OK`
- state reason
- ALARM notification delivery
- recovery notification delivery

## Lambda Errors Alarm

Alarm:

`aws-serverless-portfolio-prod-inquiry-lambda-errors`

Check Lambda health:

    aws lambda get-function-configuration \
      --function-name aws-serverless-portfolio-prod-inquiry \
      --region us-east-1

Healthy baseline:

- State: `Active`
- LastUpdateStatus: `Successful`

Review logs:

    aws logs tail \
      /aws/lambda/aws-serverless-portfolio-prod-inquiry \
      --region us-east-1 \
      --since 30m

Investigate:

- unhandled exceptions
- SNS publish failures
- IAM failures
- runtime failures
- timeouts
- malformed event handling

Do not suppress or manually clear a real alarm before understanding the cause.

## Lambda Throttles Alarm

Alarm:

`aws-serverless-portfolio-prod-inquiry-lambda-throttles`

Check account concurrency:

    aws lambda get-account-settings \
      --region us-east-1

Investigate:

- unusual request volume
- Lambda account concurrency limits
- repeated abusive requests
- unexpected retries
- broader account concurrency usage

Do not increase concurrency automatically without identifying the cause.

## API Gateway 5xx Alarm

Alarm:

`aws-serverless-portfolio-prod-inquiry-api-5xx`

Review API access logs:

    aws logs tail \
      /aws/apigateway/aws-serverless-portfolio-prod-inquiry-access \
      --region us-east-1 \
      --since 30m

Investigate:

- Lambda integration failures
- invocation permission failures
- integration latency
- infrastructure configuration errors
- upstream Lambda errors

Also verify Lambda health.

## Verify User-Facing Service

Check CloudFront:

    curl -I https://d1wnw5kep14m5j.cloudfront.net

Expected:

`HTTP 200`

Avoid repeatedly submitting real inquiries solely for incident diagnosis unless end-to-end validation is necessary.

## Terraform Safety

Before infrastructure changes:

    terraform \
      -chdir=infra/environments/prod \
      plan \
      -input=false \
      -no-color \
      -detailed-exitcode

Interpretation:

- exit code 0: no changes
- exit code 1: Terraform error
- exit code 2: proposed changes exist

Never apply an unreviewed production plan.

Production change process:

1. test locally
2. commit
3. push
4. verify CI
5. persist production desired state
6. create a saved plan
7. inspect exact mutations
8. record the plan hash
9. apply the exact reviewed saved plan
10. verify live resources
11. run a convergence plan

## Recovery

For a real incident, do not manually force an alarm to `OK`.

The alarm should recover when CloudWatch evaluates the underlying metric as healthy.

After recovery:

1. confirm alarm state is `OK`
2. confirm service health
3. validate application behavior if necessary
4. confirm Terraform convergence
5. confirm recovery notification delivery
6. record the incident timeline
7. document root cause and remediation

## Controlled Alarm Testing

For notification-path testing, CloudWatch alarm state can be changed without deliberately breaking production.

Example:

    aws cloudwatch set-alarm-state \
      --region us-east-1 \
      --alarm-name aws-serverless-portfolio-prod-inquiry-lambda-errors \
      --state-value ALARM \
      --state-reason "Controlled observability drill."

A controlled test should:

- begin from a healthy state
- verify ALARM notification delivery
- verify the application remains healthy
- verify alarm history
- allow real metric evaluation to restore the correct state
- verify recovery notification delivery
- finish with Terraform converged

Do not use manual alarm-state changes to conceal or clear a real incident.

## Healthy Baseline

Expected production baseline after Day 38:

- Lambda Errors alarm: `OK`
- Lambda Throttles alarm: `OK`
- API Gateway 5xx alarm: `OK`
- Lambda State: `Active`
- Lambda LastUpdateStatus: `Successful`
- Terraform state objects: 29
- Terraform convergence: `No changes`
- operations SNS subscribers: 1 confirmed
