# Production CloudFront 5xx Alarm Evidence — August 7, 2026

## Day 30 Goal

Add the first production CloudWatch alarm through Terraform while preserving
the production zero-drift and controlled-change workflow.

## Starting State

Before the change:

```text
Managed resources: 7
Data sources: 1
CloudFront HTTP: 200
Direct S3 HTTP: 403
Existing CloudWatch alarm: none
```

The Terraform production environment was at zero drift before monitoring was
introduced.

## Alarm Design

The production alarm monitors:

```text
Namespace:           AWS/CloudFront
Metric:              5xxErrorRate
Statistic:           Average
Period:              300 seconds
Threshold:           5%
Comparison:          GreaterThanOrEqualToThreshold
Evaluation periods:  3
Datapoints to alarm: 2
Treat missing data:  notBreaching
DistributionId:      EUWNERX790PYN
Region:              Global
```

The module defaults the alarm to disabled.

Production explicitly enables the alarm.

Development remains unchanged because it does not enable the alarm.

## Terraform Testing

Module test suite after the monitoring change:

```text
Success! 14 passed, 0 failed.
```

Validation:

```text
Module validate: success
Production validate: success
```

## CI

Git commit:

```text
02a4302 Add CloudFront 5xx monitoring alarm
```

GitHub Actions:

```text
Workflow: Terraform Static Site Module Tests
Run ID:   31154743847
Result:   success
```

## Reviewed Production Plan

The first production plan after the previous zero-drift milestone produced:

```text
Plan: 1 to add, 0 to change, 0 to destroy.

Create only:     1
Update in place: 0
Delete only:     0
Replacement:     0
No-op:           7
```

Only this resource was scheduled for creation:

```text
module.static_site.aws_cloudwatch_metric_alarm.cloudfront_5xx[0]
```

Every existing production resource remained no-op.

Reviewed saved-plan SHA256:

```text
70b4c7444b7cc6e3bea8f0a8d5c59fc973cfe44ea9c5130d8f34a4f73d844058
```

## Production Apply

The reviewed saved plan was applied directly after its checksum and resource
scope were revalidated.

Result:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

After apply:

```text
Managed resources: 8
Data sources: 1
CloudFront HTTP: 200
Direct S3 HTTP: 403
```

## Live Alarm Verification

CloudWatch reported:

```text
State:               OK
Metric:              5xxErrorRate
Namespace:           AWS/CloudFront
Statistic:           Average
Period:              300
Threshold:           5
Evaluation periods:  3
Datapoints to alarm: 2
Treat missing data:  notBreaching
```

Alarm actions:

```text
[]
```

The alarm currently detects failures but does not yet send notifications.

## Post-Apply Convergence

A fresh Terraform production plan was run after the alarm creation.

Result:

```text
No changes. Your infrastructure matches the configuration.

terraform plan exit code: 0

Changed managed resources: 0
No-op managed resources:   8
```

All managed resources were no-op.

Production successfully returned to zero drift after the intentional change.

Post-apply convergence plan SHA256:

```text
5c24138882a2905628208164ab807fd2edcf7a1e3793bd812136c273ebd7cb0f
```

## Final Production State

```text
S3 bucket:                managed
S3 Public Access Block:   managed
S3 versioning:            managed
S3 encryption:            managed
CloudFront OAC:           managed
CloudFront distribution:  managed
S3 bucket policy:         managed
CloudWatch 5xx alarm:     managed

Managed resources: 8
Data sources: 1

CloudFront HTTP: 200
Direct S3 HTTP: 403

Terraform drift: none
```

## Day 30 Status

Completed:

- Designed CloudFront 5xx monitoring
- Added alarm as an opt-in Terraform module feature
- Preserved dev behavior
- Enabled monitoring in production
- Added Terraform tests
- Passed 14/14 module tests
- Passed Terraform validation
- Passed GitHub Actions CI
- Reviewed exact production plan
- Verified 1 add / 0 change / 0 destroy
- Applied the reviewed saved plan
- Verified the live CloudWatch alarm
- Verified production availability
- Ran post-apply convergence plan
- Returned production to zero drift

## Next

Add a notification path so the CloudWatch alarm can actively alert when a
production incident occurs.
