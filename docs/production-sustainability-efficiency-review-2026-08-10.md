# Production Sustainability and Architecture Efficiency Review — August 10, 2026

## Executive Summary

Day 34 evaluated whether the production AWS portfolio architecture can be
made more resource-efficient without weakening security, reliability, or
operability.

The result was intentionally:

**No production infrastructure change.**

The workload is already extremely small and uses a minimal managed-service
architecture:

- Amazon S3 for private static-object storage
- Amazon CloudFront for public HTTPS delivery and caching
- Origin Access Control for private-origin access
- CloudWatch for the existing production 5xx alarm
- Amazon SNS for alarm notification
- Terraform for infrastructure management

The review found no measured requirement that justifies adding more
infrastructure.

---

## Business Problem

The portfolio needs to deliver a small public static website securely,
reliably, and efficiently.

The sustainability question is not:

> What additional AWS services can be added?

The question is:

> Can the required customer outcome be delivered with fewer resources,
> less unnecessary processing, less unnecessary data movement, and minimal
> operational complexity?

For the current workload, the existing architecture already meets that goal.

---

## Business Context Gate

### Business outcome

Deliver the portfolio website publicly over HTTPS while maintaining a private
S3 origin.

### Users affected

Visitors to the portfolio and the operator responsible for the production
environment.

### Availability requirement

The CloudFront delivery path must remain operational.

### Security requirement

Direct public access to S3 must remain blocked.

### Performance requirement

The site should be delivered efficiently, but current traffic does not justify
additional performance infrastructure.

### Cost and sustainability constraint

Avoid infrastructure whose ongoing resource consumption or operational
overhead is not justified by measured workload demand.

### Complexity constraint

The architecture should remain understandable, maintainable, and proportional
to the business problem.

---

## Current Terraform Footprint

Production currently contains:

- 10 Terraform-managed resources
- 1 Terraform data source

The architecture already avoids unnecessary compute layers.

There are no EC2 instances, ECS services, EKS clusters, application load
balancers, databases, or other persistent application-compute resources in
the static-site delivery path.

---

## S3 Storage Footprint

Current production object inventory:

| Object | Size |
|---|---:|
| `index.html` | 4,238 bytes |
| `styles.css` | 2,296 bytes |

Total:

- 2 objects
- 6,534 bytes

This is an extremely small storage footprint.

---

## S3 Version Footprint

The object-version review found:

- Version count: 2
- Delete markers: 0
- `index.html` version ID: `null`
- `styles.css` version ID: `null`

Both current objects are the latest objects.

Bucket versioning state:

`NOT SET`

The objects therefore do not represent an accumulating history of versioned
copies requiring lifecycle cleanup.

---

## S3 Lifecycle Decision

Current lifecycle configuration:

`NONE`

### Decision

Do not add an S3 lifecycle policy at this time.

### Why

The bucket contains only two small current objects totaling 6,534 bytes and
has no accumulated historical object versions or delete markers.

A lifecycle rule would currently introduce configuration complexity without
removing a meaningful storage burden.

### Revisit when

A lifecycle policy becomes justified if the workload begins accumulating:

- historical versions
- temporary objects
- logs
- build artifacts
- large media assets
- archival data
- incomplete multipart uploads

---

## Encryption

Both inspected production objects report:

`ServerSideEncryption = AES256`

Existing server-side encryption remains in place.

No sustainability optimization requires weakening the storage security
configuration.

---

## CloudFront Cache Policy

Production uses:

- Policy ID:
  `658327ea-f89d-4fab-a63d-7e88639e58f6`
- Policy name:
  `Managed-CachingOptimized`

Observed configuration:

- Minimum TTL: 1 second
- Default TTL: 86,400 seconds
- Maximum TTL: 31,536,000 seconds
- Cookies in cache key: none
- Headers in cache key: none
- Query strings in cache key: none
- Gzip support: enabled
- Brotli support: enabled

This configuration provides a simple cache key and allows CloudFront to reuse
cached objects efficiently.

---

## CloudFront Distribution Efficiency

Observed distribution footprint:

- Origins: 1
- Additional cache behaviors: 0
- Price class: `PriceClass_All`
- Compression: enabled
- Allowed methods: GET and HEAD
- Cached methods: GET and HEAD
- Cache policy: `Managed-CachingOptimized`

This is appropriately simple for a static website.

There are no unnecessary application origins or additional behavior trees.

---

## Compression

CloudFront compression is enabled.

The cache policy supports:

- Gzip
- Brotli

This allows compatible clients to receive compressed representations and
reduces unnecessary network transfer compared with serving only uncompressed
responses.

The S3 source objects themselves do not specify a `Content-Encoding`.

Compression is therefore handled by the delivery layer rather than requiring
separate pre-compressed origin objects for the current tiny workload.

---

## Object Cache-Control Metadata

The current S3 objects do not have explicit `Cache-Control` metadata.

No change was made.

The production CloudFront distribution already uses a managed caching policy
with a 24-hour default TTL.

At the current traffic and deployment model, there is not enough evidence to
justify adding additional object-specific cache metadata complexity.

This can be reconsidered if deployment frequency or cache invalidation
behavior becomes a measurable operational issue.

---

## CloudFront Additional Monitoring

CloudFront additional monitoring subscription:

`NONE`

### Decision

Do not enable additional CloudFront metrics solely for Day 34.

The existing workload already has:

- standard CloudFront metrics
- a production 5xx CloudWatch alarm
- SNS notification
- a completed incident drill

Additional metrics should be enabled only when the expected operational
visibility provides enough value to justify the added monitoring footprint
and cost.

---

## Sustainability Measurement Capability

Installed AWS CLI version during review:

`aws-cli/2.36.14`

The CLI exposes the AWS Sustainability namespace, including commands for:

- estimated carbon emissions
- carbon-emissions dimension values
- estimated water allocation
- water-allocation dimension values

No Sustainability data API request was made during Day 34.

The current review therefore evaluates architectural efficiency and workload
resource usage rather than claiming a measured carbon or water result.

---

## Sustainability Measurement Follow-Up

Actual AWS Sustainability measurements should be collected only when an
appropriate reporting period is available.

A missing or zero sustainability value must not automatically be interpreted
as proof that the workload has no environmental impact.

Future measurements should be documented separately from architectural
inference.

---

## Production Health

After the efficiency review:

- CloudFront: HTTP 200
- Direct S3: HTTP 403

This demonstrates that:

- the public delivery path remains available
- the S3 origin remains private

No production change was required to achieve the Day 34 outcome.

---

## Architecture Alternatives Considered

### Add an S3 lifecycle policy

Rejected for now.

There are only two small unversioned objects and no historical versions or
delete markers to clean up.

### Enable S3 versioning

Not added as a sustainability optimization.

Versioning can be valuable for recovery requirements, but enabling it would
create additional stored object versions over time.

It should be driven by a recovery/business requirement rather than added
solely for portfolio complexity.

### Enable CloudFront additional metrics

Rejected for now.

Existing observability already covers the current customer-impacting failure
mode.

### Add another caching layer

Rejected.

CloudFront already provides the caching layer required by this workload.

### Add more CloudFront cache behaviors

Rejected.

The static site does not currently require path-specific behavior.

### Add additional origins

Rejected.

One private S3 origin satisfies the workload requirement.

### Add EC2

Rejected.

There is no server-side application workload requiring a virtual machine.

### Add ECS/Fargate

Rejected.

A two-file static site does not require containers or task orchestration.

### Add EKS/Kubernetes

Rejected.

Kubernetes would dramatically increase infrastructure and operational
complexity without addressing a current requirement.

### Add database infrastructure

Rejected.

The current website has no persistent application-data requirement.

### Add multi-region application infrastructure

Rejected.

The current workload and business requirements do not justify the additional
resources and complexity.

---

## PriceClass_All Review

The production distribution currently uses:

`PriceClass_All`

No change was made during Day 34.

The price class was inherited from the established production configuration.

Changing geographic distribution coverage should be based on actual visitor
geography, performance requirements, and cost measurements.

Reducing geographic coverage without those requirements would trade potential
user performance for an optimization that has not been demonstrated as
necessary.

---

## Sustainability Decision

### Decision

Keep the current S3 + CloudFront architecture unchanged.

### Reason

The architecture already:

- uses managed services
- avoids persistent application compute
- stores only 6,534 bytes
- contains only two objects
- has one origin
- has no unnecessary cache behaviors
- caches static content
- supports compressed delivery
- restricts HTTP methods to the required read operations
- maintains a private origin
- provides existing operational monitoring

Adding resources would increase complexity without solving a measured
business problem.

---

## Efficiency Principle

The Day 34 optimization is primarily architectural restraint.

A sustainable design is not necessarily the design with the most
"sustainability features."

For this workload, the more defensible choice is to avoid allocating,
configuring, monitoring, and maintaining infrastructure that the application
does not need.

---

## Future Re-Evaluation Triggers

The decision should be revisited if any of the following change materially:

1. Monthly traffic increases substantially.
2. Data transfer becomes a meaningful cost or performance factor.
3. S3 storage begins growing materially.
4. Versioned or temporary objects begin accumulating.
5. Visitor geography demonstrates a reason to change CloudFront coverage.
6. Cache performance becomes an operational concern.
7. Additional CloudFront metrics would meaningfully improve incident response.
8. The site gains dynamic/server-side functionality.
9. Recovery requirements justify object versioning.
10. AWS Sustainability data becomes useful for trend analysis.

---

## What Went Wrong During the Review

Two read-only command issues occurred.

### Monitoring command

The first baseline attempted an invalid CloudFront CLI operation:

`list-monitoring-subscriptions`

The correct operation was:

`get-monitoring-subscription`

The review resumed without making any production change.

### Object-version query

The first version query attempted to call `length()` on a null API field.

The follow-up query normalized missing arrays to empty arrays before counting
them.

The corrected result showed:

- 2 versions/current objects
- 0 delete markers

These were tooling/query issues only.

No infrastructure was modified.

---

## What I Learned

Day 34 reinforced several engineering principles:

1. Measure before optimizing.
2. Sustainability includes avoiding unnecessary resource allocation.
3. Caching and compression can reduce repeated origin work and data transfer.
4. More AWS services do not automatically produce a better architecture.
5. Lifecycle automation should solve an actual storage-management problem.
6. Observability depth should be proportional to operational requirements.
7. Sustainability measurements and architecture-efficiency assessments are
   related but are not the same thing.
8. A justified decision to make no change is a valid engineering outcome.
9. Production health and security should still be verified during read-only
   architecture reviews.
10. Business requirements should determine architecture complexity.

---

## Employer / Interview Explanation

> I reviewed a production static-site architecture against sustainability and
> efficiency principles instead of automatically adding another AWS service.
> I measured the actual resource footprint and found the site contained only
> two unversioned objects totaling about 6.5 KB, with one CloudFront origin,
> no additional cache behaviors, compression enabled, and an optimized managed
> cache policy. I evaluated lifecycle rules, extra monitoring, additional
> origins, compute, containers, and multi-region architecture and found none
> were justified by the workload. The resulting engineering decision was to
> keep the infrastructure unchanged, document the re-evaluation triggers, and
> preserve the existing security and availability behavior.

---

## Day 34 Outcome

Day 34 is complete with an intentional no-change decision.

Final state:

- Production infrastructure changes: 0
- Terraform plans applied: 0
- S3 objects: 2
- S3 bytes: 6,534
- Historical/delete-marker buildup: none
- CloudFront origins: 1
- Additional cache behaviors: 0
- CloudFront compression: enabled
- Managed optimized cache policy: enabled
- Optional CloudFront additional metrics: disabled
- CloudFront HTTP health: 200
- Direct S3 HTTP health: 403
- Repository remained clean throughout the infrastructure review

The current architecture remains proportional to the business problem and
does not require additional AWS infrastructure to demonstrate sustainability.
