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
- `aws-serverless-portfolio-prod-inquiry-api-4xx`

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

## API Gateway 4xx Alarm

Alarm:

`aws-serverless-portfolio-prod-inquiry-api-4xx`

Purpose:

Detect sustained abnormal client-error traffic against the production
inquiry API.

Current configuration:

- Metric: `AWS/ApiGateway 4xx`
- Statistic: `Sum`
- Threshold: `20`
- Period: `300` seconds
- Evaluation periods: `2`
- Datapoints to alarm: `2`
- Missing data: `notBreaching`

The alarm requires the threshold to be met for two consecutive five-minute
evaluation periods. An isolated client mistake should therefore not be
treated as equivalent to a sustained abnormal request pattern.

Review API access logs:

    aws logs tail \
      /aws/apigateway/aws-serverless-portfolio-prod-inquiry-access \
      --region us-east-1 \
      --since 30m

Investigate:

- malformed or invalid requests
- unexpected request bursts
- repeated abusive request patterns
- broken or misconfigured clients
- unexpected frontend behavior
- changes in request origin or request pattern

Also compare the 4xx alarm with:

- API Gateway 5xx
- Lambda Errors
- Lambda Throttles

A 4xx alarm without corresponding 5xx or Lambda failures points first toward
client-side behavior, malformed traffic, or abuse rather than an immediate
server failure.

Do not weaken validation, disable throttling, or increase limits solely to
clear the alarm.

Do not generate additional production traffic unless it is necessary for a
bounded diagnostic test.

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

Incident-response stop conditions:

- stop if the proposed Terraform plan contains unexpected destruction
- stop if the proposed Terraform plan contains unexpected replacement
- stop if the AWS account or production environment cannot be verified
- stop if repository state differs from the reviewed implementation
- stop if the saved plan differs from the reviewed plan artifact
- do not disable monitoring merely to silence an active incident
- do not make the portfolio S3 bucket public as a recovery shortcut
- do not use `terraform destroy` as an incident recovery procedure

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

## Recovery Decision Procedure

Choose the recovery method based on the failure domain. Do not begin by
changing infrastructure.

### 1. Establish the incident baseline

Before recovery:

1. verify the AWS account and production environment
2. record the current Git commit
3. confirm repository status
4. inspect current alarm states and alarm history
5. inspect relevant API Gateway and Lambda logs
6. inspect Terraform state
7. run a read-only production Terraform plan
8. identify the last known-good application and infrastructure state

Do not attempt recovery until the failure domain is understood well enough to
choose a bounded recovery method.

### 2. Application or Lambda code regression

The production inquiry Lambda now uses published immutable Lambda versions and
a Terraform-managed `live` alias.

Current rollback architecture:

- Lambda version publishing is enabled
- API Gateway invokes the `live` Lambda alias
- production currently runs through `live -> 2`
- immutable version `1` is the verified known-good rollback target
- immutable version `2` is the current production version
- Terraform supports an explicit numbered rollback target through
  `inquiry_lambda_alias_version`
- the normal production configuration leaves
  `inquiry_lambda_alias_version = null`
- the tracked rollback artifact is
  `infra/environments/prod/rollback-v1.tfvars.example`
- that artifact is intentionally not auto-loaded

The version-1 rollback path was exercised successfully in production during
the Day 50 controlled rollback rehearsal.

The proven transition was:

`live: 2 -> 1 -> 2`

Both rollback and restoration changed only the Terraform-managed `live`
alias. The Lambda package, API Gateway integration, and alias invoke
permission remained unchanged.

Before using the version-1 rollback artifact during a real incident, verify
that version 1 is still the intended known-good recovery target. Do not assume
that a named rollback artifact automatically represents the correct target
for every future incident.

For a confirmed application or Lambda code regression:

1. establish the incident baseline and identify the failure domain
2. verify the AWS account and production environment
3. record the current Git commit and confirm repository status
4. inspect current Terraform state, Lambda versions, alias target, alarms,
   API integration, and alias invoke permission
5. identify the intended immutable known-good Lambda version
6. verify the target version's code SHA and previous production evidence
7. verify the rollback input artifact is committed, reviewed, and appropriate
   for the incident
8. run relevant local tests and verify the required CI result
9. generate a fresh saved Terraform rollback plan using the explicit rollback
   artifact, for example:

   `terraform plan -var-file=rollback-v1.tfvars.example -out=<PLAN>`

10. require the plan to change only the `live` alias from the current version
    to the intended immutable rollback target
11. require the Lambda function, API Gateway integration, and alias invoke
    permission to remain no-op
12. stop if the plan contains unexplained additions, replacement, destruction,
    or unrelated mutations
13. record the exact saved-plan checksum
14. immediately before apply, reverify Git, AWS identity, Terraform state,
    Lambda version inventory, alias target, routing, permissions, and alarms
15. apply only the exact reviewed saved-plan binary
16. delete the applied binary plan so it cannot be reused
17. verify the `live` alias points to the intended rollback version
18. perform the minimum necessary controlled production validation
19. confirm through logs or equivalent evidence that the validation request
    executed on the intended numbered Lambda version
20. verify API behavior and all operational alarms
21. record the post-rollback Terraform state serial
22. if restoration is appropriate, generate a separate fresh normal-config
    saved plan
23. review the restoration plan independently and require an alias-only
    transition back to the intended production version
24. apply only that separately reviewed restoration plan
25. delete the applied restoration binary plan
26. verify restored production behavior, alarms, and Terraform convergence
27. document the incident or rehearsal timeline and all reviewed plan hashes

Do not manually repoint the alias with `aws lambda update-alias` as the normal
rollback procedure. Keep the recovery path Terraform-controlled so live AWS
configuration and reviewed desired state remain synchronized.

Do not use `$LATEST` as an immutable rollback target.

Do not manufacture a new Lambda version merely to create the appearance of a
rollback target.

Do not claim that rollback succeeded solely because Terraform applied. Verify
that production traffic actually executed on the intended numbered Lambda
version.

The Day 50 production rehearsal evidence is recorded in:

`docs/production-inquiry-lambda-rollback-rehearsal-evidence-2026-08-25.md`

### 3. Terraform configuration regression

For a confirmed Terraform configuration regression:

1. identify the last known-good configuration
2. restore or revert only the defective desired-state change
3. run formatting, validation, and relevant module tests
4. commit and push the recovery change
5. verify CI
6. create a fresh saved production plan
7. inspect every planned mutation
8. stop on unexpected additions, replacements, or destruction
9. apply only the exact reviewed saved plan
10. verify live AWS resources
11. run a convergence plan

Never assume that reverting Git alone changes production. Production changes
only when the reviewed desired state is applied.

### 4. Partial Terraform apply

A partial apply must be investigated before any second apply.

For a partial apply:

1. inspect Terraform state
2. inspect the live AWS resources
3. determine exactly which operations completed
4. determine exactly which operation failed
5. correct the desired-state cause
6. run tests
7. inspect any tainted resources before changing taint state
8. remove taint only when the existing live resource has been independently
   verified as healthy and preserving it is intentional
9. create a fresh recovery plan
10. verify the plan represents only the remaining intended work
11. stop on unexpected replacement or destruction
12. apply only the reviewed recovery plan
13. verify final Terraform convergence

Do not blindly rerun the original failed apply.

### 5. Terraform state recovery

The authoritative production Terraform backend is the versioned S3 backend.

State recovery is different from infrastructure recovery.

Use backend state recovery only when the Terraform state itself is confirmed
to be damaged, lost, or incorrect.

Before restoring any prior state version:

1. stop normal Terraform changes
2. verify the AWS account
3. preserve the current state object and version information
4. inspect the versioned S3 state history
5. identify the exact known-good state version
6. compare the proposed state version with live AWS resources
7. document why state restoration is necessary
8. review the restoration procedure separately

Do not restore an older state version merely because an infrastructure change
was undesirable.

Do not manually edit production Terraform state as an ad hoc recovery method.

### 6. API Gateway configuration recovery

The production HTTP API uses the `$default` stage with automatic deployment.

There is no separately managed manual promotion step in the current
architecture.

Recover API Gateway configuration through the reviewed Terraform desired
state rather than attempting to treat a prior API deployment identifier as
the primary rollback mechanism.

### 7. Monitoring and alarm recovery

Do not manually force a real operational alarm back to `OK`.

Correct the underlying failure or traffic condition and allow CloudWatch to
reevaluate the real metric.

After the metric is healthy:

1. confirm the alarm returns to `OK`
2. review the state-transition reason
3. confirm the recovery notification
4. verify related alarms
5. document the incident timeline

### Recovery stop conditions

Stop the recovery workflow if:

- the AWS account or environment cannot be verified
- the failure domain is still unknown
- the repository contains unrelated changes
- Terraform state does not match the expected environment
- the plan contains unexplained additions
- the plan contains unexpected replacement
- the plan contains unexpected destruction
- the plan differs from the reviewed saved-plan artifact
- the proposed action would weaken validation, throttling, IAM, monitoring,
  S3 privacy, or another production safety control
- the proposed recovery depends on manually hiding or clearing a real alarm

Do not use `terraform destroy` as a rollback procedure.

Do not make the production S3 bucket public as a recovery shortcut.

## Post-Recovery Verification

After the chosen recovery action, verify that the underlying production
condition is actually healthy.

Do not manually force a real alarm to `OK`. CloudWatch should return the
alarm to `OK` only when evaluation of the underlying metric shows recovery.

Verify:

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

Expected production baseline after Day 42:

- Lambda Errors alarm: `OK`
- Lambda Throttles alarm: `OK`
- API Gateway 5xx alarm: `OK`
- API Gateway 4xx alarm: `OK`
- Lambda State: `Active`
- Lambda LastUpdateStatus: `Successful`
- Terraform state objects: 30
- Terraform convergence: `No changes`
- operations SNS subscribers: 1 confirmed
