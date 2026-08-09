# Production CloudWatch Incident Drill Evidence

Date: August 8, 2026

## Objective

Verify the complete production alert lifecycle for the CloudFront 5xx
monitoring alarm.

The tested path was:

CloudFront metric
→ CloudWatch alarm
→ SNS topic
→ confirmed email notification
→ real metric reevaluation
→ recovery to OK
→ SNS recovery notification

---

## Pre-Drill Safety Verification

Before changing the alarm runtime state:

- AWS account identity was verified.
- Git working tree was clean.
- Terraform production plan reported no changes.
- Terraform plan exit code: 0.
- Terraform managed resources: 10.
- Terraform data sources: 1.
- CloudWatch alarm state: OK.
- Alarm actions enabled: true.
- ALARM action targeted the production SNS topic.
- OK action targeted the production SNS topic.
- Confirmed email subscriptions: 1.
- CloudFront health check: HTTP 200.
- Direct S3 request: HTTP 403.

No Terraform apply was performed.

---

## Alarm Configuration

Alarm:

`2aron41-aws-portfolio-20260713-cloudfront-5xx-error-rate`

Metric configuration:

- Namespace: AWS/CloudFront
- Metric: 5xxErrorRate
- Statistic: Average
- Threshold: 5%
- Period: 300 seconds
- Evaluation periods: 3
- Datapoints to alarm: 2
- Missing data: notBreaching

Notification configuration:

- ALARM action: production SNS alert topic
- OK action: production SNS alert topic

---

## Controlled Incident Drill

The AWS CloudWatch `SetAlarmState` testing mechanism was used to
temporarily place the production alarm into the ALARM state.

The state reason explicitly identified the event as a controlled test:

`Day 32 controlled incident drill at 2026-08-09T00:55:48Z. TEST ONLY — no production incident.`

The command succeeded:

`set-alarm-state exit code: 0`

No alarm configuration was changed.

---

## ALARM Transition

CloudWatch recorded:

`OK → ALARM`

Timestamp:

`2026-08-09T00:55:49.742000+00:00`

The live alarm immediately reported the controlled test reason.

A real CloudWatch-generated ALARM notification was successfully
delivered through:

CloudWatch
→ SNS
→ confirmed email endpoint

This verified the production ALARM notification action.

---

## Automatic Recovery

The alarm was not manually forced back to OK.

CloudWatch reevaluated the actual CloudFront metric and automatically
returned the alarm to the correct runtime state.

Observed transition:

`ALARM → OK`

Timestamp:

`2026-08-09T00:56:20.739000+00:00`

The forced ALARM state therefore lasted approximately 31 seconds.

Recovery reason:

A CloudFront 5xxErrorRate datapoint of `0.0` was below the configured
5% threshold, and two missing datapoints were treated as non-breaching.

This satisfied the configured 2-of-3 evaluation logic for the
ALARM-to-OK transition.

---

## Recovery Notification

A real CloudWatch-generated OK notification was successfully delivered
through:

CloudWatch
→ SNS
→ confirmed email endpoint

This verified the production OK/recovery notification action.

Both lifecycle notifications were received:

- OK → ALARM notification: verified
- ALARM → OK notification: verified

No email address is recorded in this evidence document.

---

## Alarm History Evidence

CloudWatch alarm history recorded:

1. `OK → ALARM`
   - 2026-08-09T00:55:49.742000+00:00

2. `ALARM → OK`
   - 2026-08-09T00:56:20.739000+00:00

Earlier initialization history also contained:

`INSUFFICIENT_DATA → OK`

The Day 32 drill therefore produced a complete incident lifecycle in
CloudWatch history.

---

## Production Health During Drill

Before the drill:

- CloudFront: HTTP 200
- Direct S3: HTTP 403

After the drill:

- CloudFront: HTTP 200
- Direct S3: HTTP 403

The exercise changed only the CloudWatch alarm's temporary runtime
state.

No CloudFront resource was modified.

No S3 resource was modified.

No Terraform apply was performed.

---

## Security Controls Preserved

The notification path continues to use:

- Private S3 origin
- CloudFront Origin Access Control
- CloudWatch alarm
- SNS topic
- SNS topic policy restricted to CloudWatch
- `aws:SourceAccount` restriction
- `aws:SourceArn` restriction
- Confirmed email notification endpoint

The S3 bucket was never made public as part of the drill.

---

## Incident Response Lessons

The drill demonstrated the difference between:

### Detection

CloudWatch evaluates the CloudFront metric and determines whether the
alarm should enter ALARM.

### Notification

SNS distributes state-change notifications to confirmed subscribers.

### Recovery

The underlying metric is reevaluated independently of the forced test
state.

Once the actual metric satisfied the alarm's OK conditions, CloudWatch
automatically restored the alarm to OK.

### Verification

Alarm history plus the received ALARM and OK notifications provide
evidence that the complete monitoring path works.

---

## Operational Response Procedure

If this alarm enters ALARM during a real incident:

1. Verify that the notification identifies the production CloudFront
   5xx alarm.
2. Check the current CloudFront 5xxErrorRate metric.
3. Test the public CloudFront endpoint.
4. Inspect CloudFront distribution health and recent changes.
5. Verify the private S3 origin remains accessible through CloudFront.
6. Verify direct S3 public access remains blocked.
7. Review recent deployments or Terraform changes.
8. Determine whether the failure is caused by CloudFront, the origin,
   application content, configuration, or an AWS service issue.
9. Use the safest recovery method appropriate to the cause.
10. Confirm the CloudWatch alarm returns to OK.
11. Confirm receipt of the OK/recovery notification.
12. Document the incident, cause, remediation, and preventive action.

### Critical Security Rule

Never make the S3 bucket public as an emergency troubleshooting step.

Production should continue using:

CloudFront
→ Origin Access Control
→ private S3

---

## Day 32 Final Result

Controlled alarm-state change:

`SUCCESS`

Alarm transition:

`OK → ALARM`

Automatic metric recovery:

`ALARM → OK`

ALARM notification received:

`YES`

OK recovery notification received:

`YES`

Terraform production drift before drill:

`NONE`

Production content delivery after drill:

- CloudFront HTTP 200
- Direct S3 HTTP 403

Infrastructure resources modified:

`NONE`

Terraform apply performed:

`NO`

Day 32 incident-drill objective:

`COMPLETE`
