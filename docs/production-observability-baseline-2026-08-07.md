# Production Observability Baseline — August 7, 2026

## Day 29 Goal

Establish a read-only production observability baseline before creating alarms
or other monitoring infrastructure.

## Production Health

```text
CloudFront HTTP: 200
Direct S3 HTTP: 403
CloudFront status: Deployed
CloudFront enabled: true
```

Production remained healthy throughout the Day 29 inventory.

## CloudFront Configuration

```text
Distribution ID: EUWNERX790PYN
Domain: d1wnw5kep14m5j.cloudfront.net
Default root object: index.html
Viewer protocol policy: redirect-to-https
Allowed methods: GET, HEAD
Cached methods: GET, HEAD
Price class: PriceClass_All
HTTP version: http2
```

## Existing CloudWatch Visibility

Standard CloudFront metrics currently available:

- Requests
- BytesDownloaded
- BytesUploaded
- 4xxErrorRate
- 5xxErrorRate
- TotalErrorRate

Additional CloudFront monitoring metrics are not enabled.

Existing CloudWatch alarms:

```text
NONE
```

The environment currently has telemetry but no alerting.

## S3 Security Baseline

Verified:

```text
BlockPublicAcls: true
BlockPublicPolicy: true
IgnorePublicAcls: true
RestrictPublicBuckets: true
Encryption: AES256
Bucket policy public: false
Direct S3 HTTP: 403
```

## Traffic Baseline

Observation window:

```text
Last 24 hours: 32 requests
Last 7 days:   39 requests
```

Observed hourly request datapoints during the last 24 hours:

```text
1
17
14
```

The production portfolio is currently a very low-traffic workload with long
periods of no requests.

## Error Baseline

```text
24-hour 5xxErrorRate:   0%
24-hour 4xxErrorRate:   0%
24-hour TotalErrorRate: 0%

7-day peak 5xxErrorRate: 0%
7-day peak 4xxErrorRate: 0%
```

## Initial Alarm Design

The first proposed production alarm will monitor CloudFront 5xx errors.

```text
Metric:              5xxErrorRate
Namespace:           AWS/CloudFront
Statistic:           Average
Period:              300 seconds
Threshold:           5%
Comparison:          GreaterThanOrEqualToThreshold
Evaluation periods:  3
Datapoints to alarm: 2
Treat missing data:  notBreaching

DistributionId = EUWNERX790PYN
Region         = Global
```

### Why 2 of 3 Periods?

Because traffic is low, a single failed request could produce a very high error
percentage for one period.

Requiring two breaching periods out of three reduces noise from an isolated
failure while still detecting a persistent CloudFront or origin problem.

### Why Missing Data Is Not Breaching

Periods with no traffic are normal for this site.

Missing CloudWatch datapoints should therefore not be interpreted as an outage.

## Decisions

For the initial monitoring layer:

- Create a CloudFront 5xx alarm.
- Do not alarm on request volume.
- Do not create a 4xx alarm yet.
- Do not create a TotalErrorRate alarm yet.
- Do not enable paid additional CloudFront metrics yet.
- Add an independent uptime check later.

## Day 29 Status

Completed:

- Production health verification
- CloudFront monitoring inventory
- S3 security verification
- CloudWatch metric inventory
- Existing alarm inventory
- 24-hour traffic baseline
- 7-day traffic baseline
- Error-rate baseline
- Initial alarm design

No AWS resources were changed.

No CloudWatch alarms were created.

No Terraform plan or apply was run.

## Next

**Day 30 — Implement the CloudFront 5xx alarm in Terraform, add tests, run CI,
and review the production Terraform plan before any AWS change.**
