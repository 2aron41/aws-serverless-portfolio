# Production Inquiry Operational Readiness Evidence — August 20, 2026

## Purpose

Day 43 reviewed and updated the existing production inquiry incident runbook
so that it matches the current four-alarm production monitoring architecture.

No new infrastructure was created and no production configuration changed.

## Starting State

At the beginning of Day 43:

- repository was clean and synchronized
- production Terraform state contained 30 objects
- Terraform was fully converged
- four inquiry operational alarms existed
- all four alarms were `OK`
- the existing incident runbook predated the API Gateway 4xx alarm
- the runbook still documented the old 29-object production baseline

## Runbook Audit

The existing runbook was retained rather than replaced.

Audit findings:

- Lambda Errors guidance: present
- Lambda Throttles guidance: present
- API Gateway 5xx guidance: present
- API Gateway 4xx guidance: missing
- Terraform safety guidance: present
- recovery guidance: present
- controlled alarm testing guidance: present
- healthy baseline: stale
- explicit production stop conditions: incomplete

The existing runbook was therefore extended instead of duplicated.

## API Gateway 4xx Incident Guidance

Added a dedicated section for:

`aws-serverless-portfolio-prod-inquiry-api-4xx`

Documented production configuration:

- Namespace: `AWS/ApiGateway`
- Metric: `4xx`
- Statistic: `Sum`
- Threshold: `20`
- Period: `300` seconds
- Evaluation periods: `2`
- Datapoints to alarm: `2`
- Missing data: `notBreaching`

The runbook now explains that a 4xx alarm should first be investigated as
client-side, malformed-traffic, or abuse-related behavior when corresponding
5xx or Lambda failures are absent.

Documented investigation areas include:

- malformed or invalid requests
- unexpected request bursts
- repeated abusive request patterns
- broken or misconfigured clients
- unexpected frontend behavior
- changes in request origin or request pattern

The runbook explicitly warns against weakening validation, disabling
throttling, or increasing limits merely to clear the alarm.

## Incident Safety Controls

Added explicit stop conditions for production response:

- stop on unexpected Terraform destruction
- stop on unexpected Terraform replacement
- stop when AWS account or environment cannot be verified
- stop when repository state differs from reviewed implementation
- stop when a saved plan differs from the reviewed artifact
- do not disable monitoring merely to silence an incident
- do not make the portfolio S3 bucket public as a recovery shortcut
- do not use `terraform destroy` as an incident recovery procedure

These controls supplement the existing requirement to never apply an
unreviewed production plan.

## Healthy Baseline Update

The runbook baseline was updated from Day 38 to Day 42.

Current documented baseline:

- Lambda Errors alarm: `OK`
- Lambda Throttles alarm: `OK`
- API Gateway 5xx alarm: `OK`
- API Gateway 4xx alarm: `OK`
- Lambda State: `Active`
- Lambda LastUpdateStatus: `Successful`
- Terraform state objects: `30`
- Terraform convergence: `No changes`
- operations SNS subscribers: 1 confirmed

The obsolete 29-object baseline was removed.

## Command Validation

The new API Gateway access-log command was reviewed and corrected to remain
readable and copyable as a multiline AWS CLI command.

Relevant AWS CLI service commands were checked locally for availability:

- CloudWatch alarm inspection
- CloudWatch alarm history
- Lambda configuration
- Lambda account settings
- CloudWatch Logs tail
- controlled CloudWatch alarm-state testing

## Repository Change

Commit:

`b0ade4baf2f721a53d244caba96a33e928390e09`

Commit message:

`Update inquiry incident runbook`

Change scope:

- `docs/inquiry-incident-runbook.md`

Commit result:

- 1 file changed
- 72 insertions
- 2 deletions

No Terraform files changed.

## AWS Impact

Day 43 AWS configuration changes:

`0`

No requests were sent.

No Terraform apply was performed.

No CloudWatch alarms were modified.

No SNS resources were modified.

## Final Result

Day 43 improved production operational readiness by bringing the existing
incident runbook in line with the current production architecture.

Final status:

- four operational alarms documented
- API Gateway 4xx triage procedure documented
- production stop conditions documented
- healthy baseline updated to 30 state objects
- obsolete baseline removed
- runbook committed and pushed
- repository clean and synchronized
- Terraform changes: 0
- AWS configuration changes: 0
