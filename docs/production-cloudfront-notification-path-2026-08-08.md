# Production CloudFront Notification Path Evidence

Date: August 8, 2026

## Objective

Extend the production CloudFront 5xx monitoring alarm with a real
notification path so operational incidents can generate an email alert.

The completed path is:

CloudFront 5xx metric
→ CloudWatch alarm
→ SNS topic
→ confirmed email subscription

The CloudWatch alarm also sends an SNS notification when the alarm
returns to the OK state.

---

## Production Safety Baseline

Before the Day 31 change:

- Terraform managed resources: 8
- Terraform data sources: 1
- CloudWatch alarm state: OK
- AlarmActions: empty
- OKActions: empty
- SNS topics: 0
- CloudFront health check: HTTP 200
- Direct S3 object request: HTTP 403
- Git working tree: clean

No existing S3, CloudFront, OAC, encryption, versioning, or bucket-policy
resource required modification.

---

## Terraform Design

Notification infrastructure is optional at the reusable module level.

Module variable:

- `enable_cloudfront_alarm_notifications`
- Type: bool
- Default: false

Production enables the notification feature.

Development does not enable the notification feature and therefore does
not create production notification infrastructure.

### SNS Topic

Terraform manages:

`module.static_site.aws_sns_topic.cloudfront_alerts[0]`

Production topic name:

`2aron41-aws-portfolio-20260713-cloudfront-alerts`

The SNS topic inherits the production Terraform tags.

### CloudWatch Alarm Integration

Terraform manages:

`module.static_site.aws_cloudwatch_metric_alarm.cloudfront_5xx[0]`

When notifications are enabled:

- `alarm_actions` targets the SNS topic.
- `ok_actions` targets the same SNS topic.
- `insufficient_data_actions` remains unused.

This provides notifications for both an incident entering the ALARM
state and recovery back to the OK state.

---

## SNS Security Policy

Terraform manages:

`module.static_site.aws_sns_topic_policy.cloudfront_alerts[0]`

The topic policy permits:

- Principal: `cloudwatch.amazonaws.com`
- Action: `SNS:Publish`

The permission is restricted using:

- `aws:SourceAccount`
- `aws:SourceArn`

The SourceArn is restricted to the specific production CloudWatch 5xx
alarm.

This reduces confused-deputy risk compared with allowing unrestricted
CloudWatch publishing to the topic.

---

## Terraform Testing

The module test suite was expanded to verify:

- Notifications remain disabled by default.
- No SNS topic is planned when notification support is disabled.
- No alarm actions are configured when notifications are disabled.
- No OK actions are configured when notifications are disabled.
- Exactly one SNS topic is planned when notifications are enabled.
- Exactly one SNS topic policy is planned when notifications are enabled.
- The alarm contains one ALARM notification action.
- The alarm contains one recovery notification action.
- Both actions target the SNS topic.

The SNS ARN is a computed value during planning, so the notification
test uses a plan-time resource override to make the ARN deterministic.

Final local result:

`Success! 15 passed, 0 failed.`

---

## GitHub Actions CI

Notification implementation commit:

`fd2136a Add CloudFront alarm notification topic`

Terraform CI run:

`31240546681`

Result:

`success`

SNS publish-policy security commit:

`90edd86 Secure CloudWatch SNS publishing`

Terraform CI run:

`31240798197`

Result:

`success`

CI executed:

- Terraform format check
- Terraform initialization without backend
- Terraform validation
- Terraform native tests

---

## Production Plan Review

The reviewed production plan contained exactly:

- 2 resources to add
- 1 resource to update in place
- 0 resources to destroy
- 0 replacements
- 7 existing managed resources with no changes

Changed resources:

1. Create:
   `module.static_site.aws_sns_topic.cloudfront_alerts[0]`

2. Create:
   `module.static_site.aws_sns_topic_policy.cloudfront_alerts[0]`

3. Update in place:
   `module.static_site.aws_cloudwatch_metric_alarm.cloudfront_5xx[0]`

All existing core resources remained no-op:

- S3 bucket
- S3 Block Public Access
- S3 versioning
- S3 server-side encryption
- CloudFront Origin Access Control
- CloudFront distribution
- S3 bucket policy

Production plan summary:

`Plan: 2 to add, 1 to change, 0 to destroy.`

The exact-change safety gate passed.

---

## Reviewed Plan Artifact

Saved plan:

`/workspaces/terraform-production-backups/2026-08-05-pre-import/terraform-plans/day31-notification-path.tfplan`

Reviewed SHA256:

`1a2f8ff8762066032ecf752cfc3e7594d927a27ee00959fd3c5c213356c24365`

The checksum was verified immediately before apply.

Only the reviewed saved plan was applied.

---

## Production Apply

Terraform result:

`Apply complete! Resources: 2 added, 1 changed, 0 destroyed.`

Post-apply Terraform state:

- Managed resources: 10
- Data sources: 1

No S3 or CloudFront content-delivery resource was replaced or destroyed.

---

## CloudWatch Alarm Verification

Final live alarm configuration:

- State: OK
- Namespace: AWS/CloudFront
- Metric: 5xxErrorRate
- Statistic: Average
- Period: 300 seconds
- Threshold: 5%
- Evaluation periods: 3
- Datapoints to alarm: 2
- Missing data: notBreaching
- ALARM action: production SNS topic
- OK action: production SNS topic

The monitoring thresholds were not changed during Day 31.

---

## Email Subscription

The email endpoint is intentionally not stored in Git or Terraform.

Reason:

Managing the email endpoint through Terraform would place the endpoint
inside Terraform state.

Instead, the email subscription was created manually through the AWS CLI
and confirmed through the AWS-generated subscription email.

Final subscription state:

- Confirmed email subscriptions: 1
- Pending subscriptions: 1

The remaining pending subscription resulted from an initially mistyped
email address.

No email address is recorded in this evidence file.

---

## End-to-End Delivery Test

A controlled SNS message was published directly to the production alert
topic.

Test subject:

`Day 31 CloudFront Alert Test`

Message:

`TEST ONLY: Production CloudFront alert notifications are configured successfully. No incident has occurred.`

SNS accepted the publish request.

Message ID:

`43179f0a-8a7e-5dd4-a5c8-fdfa49b690c4`

The message was successfully received by the confirmed email endpoint.

This proves the operational path:

SNS topic
→ confirmed email subscription
→ recipient inbox

No CloudWatch alarm state was artificially changed for this delivery
test.

---

## Production Health Verification

After the Terraform apply and notification test:

- CloudFront request: HTTP 200
- Direct S3 object request: HTTP 403

This confirms:

- CloudFront continues serving the production site.
- The S3 origin remains inaccessible through direct public requests.

---

## Terraform Convergence

A final production Terraform plan was executed after deployment.

Result:

`No changes. Your infrastructure matches the configuration.`

Detailed exit code:

`0`

Final Terraform state:

- Managed resources: 10
- Data sources: 1

This confirms Terraform and the Terraform-managed AWS infrastructure are
fully converged with zero detected drift.

The manually managed email subscription is intentionally outside
Terraform state.

---

## Operational Runbook

### When the CloudWatch Alarm Enters ALARM

1. Read the SNS email notification.
2. Confirm the affected alarm is the production CloudFront 5xx alarm.
3. Check CloudFront distribution status.
4. Test the public CloudFront URL.
5. Inspect the CloudFront `5xxErrorRate` metric.
6. Check whether the S3 origin is healthy and still private.
7. Review recent infrastructure or application changes.
8. Determine whether the failure is CloudFront, origin, configuration,
   deployment, or transient AWS behavior.
9. Restore service using the safest appropriate recovery method.
10. Confirm the alarm returns to OK.
11. Verify receipt of the recovery notification.
12. Document the incident and corrective action.

### Important Security Rule

Do not make the S3 bucket public as an incident workaround.

Production should continue using:

CloudFront
→ Origin Access Control
→ private S3 bucket

### Terraform Rule

Never run a production apply without first:

1. Verifying AWS identity.
2. Confirming Git is clean.
3. Running Terraform validation.
4. Reviewing a saved production plan.
5. Classifying every changed resource.
6. Confirming zero unexpected deletes or replacements.
7. Verifying production health before the apply.
8. Applying only the reviewed saved plan.
9. Running post-apply health verification.
10. Running a final convergence plan.

---

## Day 31 Final Status

Completed:

- SNS production alert topic
- CloudWatch-to-SNS least-privilege topic policy
- CloudWatch ALARM notification action
- CloudWatch OK/recovery notification action
- Email subscription confirmation
- Real SNS email delivery test
- Terraform module testing
- GitHub Actions validation
- Controlled production plan
- Saved-plan checksum verification
- Controlled production apply
- Post-apply health verification
- Zero-drift convergence verification

Final status:

- Terraform tests: 15 passed
- GitHub Actions CI: success
- Terraform managed resources: 10
- Terraform data sources: 1
- Production Terraform drift: none
- CloudWatch alarm: OK
- Confirmed notification destination: 1
- End-to-end SNS email delivery: verified
- CloudFront: HTTP 200
- Direct S3: HTTP 403
- Production resources destroyed: 0
