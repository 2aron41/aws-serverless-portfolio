# Production FinOps and Cost Attribution Baseline — August 9, 2026

## Executive Summary

Day 33 established a production FinOps baseline for the AWS serverless
portfolio workload and improved cost attribution without changing the
application architecture or security boundary.

The production workload remains intentionally simple:

- Amazon S3 stores the static website privately.
- Amazon CloudFront delivers the website publicly over HTTPS.
- Origin Access Control restricts S3 access to CloudFront.
- Terraform manages production infrastructure.
- CloudWatch monitors CloudFront 5xx errors.
- Amazon SNS provides alarm notifications.
- An AWS Budget provides a basic account-level spending guardrail.

The workload currently has very low traffic and storage requirements.
The existing serverless architecture is therefore financially appropriate
for the current business problem. Adding always-on compute or container
platforms such as EC2, ECS, or EKS would add cost and operational complexity
without a demonstrated workload requirement.

Day 33 also standardized governance tags on the production S3 bucket and
CloudFront distribution so future cost reporting can identify resources by
project, environment, owner, purpose, and Terraform management status.

---

## Business Problem

The production portfolio needs to:

1. Deliver a public static website reliably over HTTPS.
2. Keep the S3 origin private.
3. Maintain infrastructure through Terraform.
4. Detect customer-impacting CloudFront failures.
5. Notify the operator when monitored failures occur.
6. Keep operating cost appropriate for an extremely small workload.
7. Make production resources attributable for future FinOps analysis.

The goal is not to demonstrate the largest possible AWS architecture.

The goal is to use the smallest architecture that satisfies the workload's
security, reliability, operational, and cost requirements.

---

## Business Context Gate

### What business problem does the architecture solve?

Securely and reliably deliver a public portfolio website while keeping the
origin private and operational cost low.

### Who is affected?

Visitors to the public portfolio and the operator responsible for maintaining
the site.

### Availability requirements

The website should remain publicly reachable through CloudFront.

CloudFront health is verified through HTTP requests and CloudWatch monitoring.

### Security requirements

- S3 must remain private.
- Direct S3 object access must remain blocked.
- CloudFront must access S3 through the existing OAC.
- The S3 bucket policy must restrict CloudFront access to the exact production
  distribution.
- Infrastructure changes must remain controlled through Terraform.

### Performance requirements

Current traffic volume is extremely small, so there is no demonstrated need
for additional compute, autoscaling, containers, Kubernetes, or multi-region
application infrastructure.

### Cost requirements

The architecture should remain inexpensive at the current traffic level while
maintaining security and observability.

### Operational constraints

- Production resources already existed before Terraform import.
- Imported configuration must not be changed accidentally.
- Production changes require saved plans, plan review, checksums, CI, health
  checks, and post-apply convergence verification.

---

## Production Architecture in Scope

Production infrastructure currently contains 10 Terraform-managed resources
plus one Terraform data source.

Managed resources:

1. S3 bucket
2. S3 Public Access Block
3. S3 versioning configuration
4. S3 server-side encryption configuration
5. CloudFront Origin Access Control
6. CloudFront distribution
7. S3 bucket policy
8. CloudWatch CloudFront 5xx alarm
9. SNS alert topic
10. SNS topic policy

Current policy-document generation uses one Terraform data source.

---

## Workload Baseline

Observed production workload during Day 33:

| Metric | Baseline |
|---|---:|
| CloudFront viewer requests, previous 30 days | 137 |
| Approximate requests per day | 4.57 |
| CloudFront bytes downloaded | 451,554 bytes |
| CloudFront data downloaded | approximately 0.4306 MiB |
| CloudFront data downloaded | approximately 0.000421 GiB |
| Average transfer per request | approximately 3.22 KiB |
| S3 stored data | 6,614 bytes |
| S3 stored data | approximately 0.0063 MiB |
| S3 objects | 2 |

These values demonstrate that the current production workload is extremely
small.

The architecture should therefore continue to favor managed, usage-based
services instead of introducing always-on compute.

---

## Billing and Budget Baseline

Existing AWS Budget:

- Name: `Aaron-Zero-Spend-Budget`
- Budget type: Cost
- Period: Monthly
- Budget limit: $1 USD
- Reported actual spend during review: $0.00
- Forecast: unavailable at the time of review
- Alert type: Actual
- Alert threshold: greater than $0.01
- Threshold type: absolute value

### Important billing interpretation

The budget configuration includes credits when calculating cost.

Therefore, the observed `$0.00` budget value must **not** be interpreted as
proof that every underlying AWS service has zero gross economic cost.

It represents the account's current billing view under its existing credits
and account plan.

---

## AWS Account Plan Context

During Day 33 the account reported:

- Plan type: Free
- Plan status: Active
- Remaining credits: $120 USD
- Credit expiration: January 14, 2027

This is important when interpreting current billing results.

A zero-dollar net bill while credits are available does not demonstrate that
the architecture would always have a zero-dollar gross cost.

---

## CloudFront Pricing Configuration

The production CloudFront distribution currently uses:

- `PriceClass_All`
- HTTP/2
- IPv6 enabled
- No Web ACL
- No CloudFront additional monitoring subscription
- No CloudFront flat-rate pricing-plan subscription was found during the Day 33
  review

`PriceClass_All` was preserved because it is part of the imported production
configuration.

A future cost optimization could evaluate a narrower CloudFront price class,
but only if geographic performance requirements show that doing so is
appropriate.

Changing the price class solely to make the architecture appear cheaper would
not be justified without a business requirement.

---

## Account-Level Free-Tier Usage Observed

The Free Tier usage review returned activity for:

- Amazon CloudWatch alarm monitoring
- Amazon CloudWatch requests
- Amazon SNS email delivery attempts
- Amazon SNS requests
- AWS Glue catalog requests
- Amazon SQS requests

A very small SNS request count was also observed in `us-east-2`.

No persistent SNS topic or CloudWatch alarm was found there during the review,
so the cause of that isolated account-level request was not attributed to this
portfolio workload.

Account-level Free Tier activity should not automatically be interpreted as
portfolio-specific usage.

---

## Cost Explorer Decision

No Cost Explorer API request was made during Day 33.

The existing workload metrics, Budget data, Free Tier data, architecture
inventory, and resource-tag review were sufficient to establish the initial
FinOps baseline without introducing an unnecessary billing-analysis API call.

A detailed service-by-service billing analysis can be performed later if the
workload or spending becomes material.

---

## Initial Cost Attribution Gap

Before Day 33 modernization:

### S3 bucket

No tags were present.

### CloudFront distribution

Only this existing tag was present:

- `Name = aaron-portfolio-cdn`

### CloudWatch alarm

Already contained the workload governance tags.

### SNS topic

Already contained the workload governance tags.

This meant the workload had inconsistent cost and governance metadata across
its major production resources.

---

## Governance Tag Standard

Day 33 standardized the following workload tags:

- `Project = aws-serverless-portfolio`
- `Environment = prod`
- `ManagedBy = Terraform`
- `Owner = 2aron41`
- `Purpose = Production portfolio website`

The existing CloudFront tag was preserved:

- `Name = aaron-portfolio-cdn`

---

## Terraform Tag Design

The reusable static-site module intentionally supports resource-specific tag
overrides.

That behavior was originally required to reconcile the imported production
environment without introducing tag drift.

Instead of changing the reusable module's import behavior, Day 33 implemented
the governance modernization in the production environment.

Production now creates a common workload tag set and merges it into the S3 and
CloudFront resource-specific tag maps.

This preserved:

- reusable module behavior
- existing import-compatibility tests
- the existing CloudFront `Name` tag

while allowing production to adopt the governance standard.

---

## First Production Plan — Rejected

The first Day 33 production plan proposed:

- CloudFront distribution: update in place
- S3 bucket: update in place
- S3 bucket policy: update in place

Plan summary:

- 0 create
- 3 update
- 0 destroy

The S3 bucket-policy update was not expected.

The plan was rejected and never applied.

---

## Unexpected Bucket-Policy Dependency

The bucket policy was generated through an
`aws_iam_policy_document` data source.

Its document referenced:

- the managed S3 bucket ARN
- the managed CloudFront distribution ARN

When those resources had pending metadata/tag updates, Terraform deferred the
policy-document calculation.

The resulting policy value became unknown during planning, which made
Terraform propose an S3 bucket-policy update even though the actual CloudFront
distribution identity remained unchanged.

The CloudFront distribution ID and ARN remained stable.

This was treated as unnecessary dependency churn rather than accepted as an
unreviewed production policy write.

---

## Policy-Decoupling Design

An optional variable was added:

`cloudfront_policy_source_arn`

Behavior:

### Normal/new deployments

When the variable is null, the module continues to derive the SourceArn from
the managed CloudFront distribution.

### Imported production

Production supplies the already-known CloudFront distribution ARN explicitly.

This allows Terraform to calculate the production bucket policy without
depending on metadata changes to the managed CloudFront resource.

The existing security boundary remains unchanged because the explicit ARN is
the same exact production distribution ARN already authorized by the bucket
policy.

---

## Terraform Tests

Two new tests were added:

1. Explicit CloudFront policy SourceArn planning
2. Invalid CloudFront policy SourceArn rejection

A mocked `aws_iam_policy_document` value initially produced invalid JSON during
testing.

The test was corrected using an explicit mock-data override containing valid
policy JSON.

Final Terraform module test result:

`17 passed, 0 failed`

All existing tests continued to pass.

---

## Git and CI Evidence

Implementation commit:

`ec7211d Add production cost attribution tags`

GitHub Actions run:

`31351243131`

Workflow:

`Terraform Static Site Module Tests`

Result:

`success`

Terraform CI job completed successfully before the production apply.

---

## Approved Production Plan V2

The corrected V2 production plan contained exactly:

- CloudFront distribution: update in place
- S3 bucket: update in place
- S3 bucket policy: no-op
- Origin Access Control: no-op
- CloudWatch alarm: no-op
- S3 Public Access Block: no-op
- S3 encryption configuration: no-op
- S3 versioning configuration: no-op
- SNS topic: no-op
- SNS topic policy: no-op

Plan summary:

`Plan: 0 to add, 2 to change, 0 to destroy.`

No creates, deletes, or replacements were present.

### Reviewed plan SHA256

`2eb06b31051261954b9772dda4ba8e1a869a9180ac18002a183867990ede62c5`

The checksum was verified again immediately before apply.

---

## Controlled Production Apply

The exact reviewed V2 saved plan was applied.

Result:

`Apply complete! Resources: 0 added, 2 changed, 0 destroyed.`

Terraform apply exit code:

`0`

Only the approved metadata changes were applied.

The rejected V1 plan was never applied.

---

## Live S3 Tags After Apply

The production S3 bucket now contains:

- `Project = aws-serverless-portfolio`
- `Environment = prod`
- `Owner = 2aron41`
- `Purpose = Production portfolio website`
- `ManagedBy = Terraform`

---

## Live CloudFront Tags After Apply

The production CloudFront distribution now contains:

- `Name = aaron-portfolio-cdn`
- `Project = aws-serverless-portfolio`
- `Environment = prod`
- `Owner = 2aron41`
- `Purpose = Production portfolio website`
- `ManagedBy = Terraform`

The pre-existing `Name` tag was preserved.

---

## Security Verification

The S3 bucket policy remained restricted to CloudFront.

Verified production policy properties:

- Policy ID: `PolicyForCloudFrontPrivateContent`
- Policy version: `2008-10-17`
- Statement SID: `AllowCloudFrontServicePrincipal`
- Effect: Allow
- Principal: `cloudfront.amazonaws.com`
- Action: `s3:GetObject`
- Resource: production bucket objects
- Condition operator: `ArnLike`
- SourceArn: exact production CloudFront distribution ARN

Verified SourceArn:

`arn:aws:cloudfront::510497448584:distribution/EUWNERX790PYN`

The policy security boundary was unchanged by the tagging operation.

---

## Observability Verification

After the change:

- CloudWatch 5xx alarm state: `OK`
- Alarm actions enabled: `true`
- CloudFront distribution status: `Deployed`
- CloudFront distribution enabled: `true`

The existing observability and notification system remained intact.

---

## Production Health Verification

Before apply:

- CloudFront: HTTP 200
- Direct S3: HTTP 403

After apply:

- CloudFront: HTTP 200
- Direct S3: HTTP 403

After convergence verification:

- CloudFront: HTTP 200
- Direct S3: HTTP 403

This confirms that the public delivery path continued working and the private
S3 security boundary remained enforced.

---

## Post-Apply Terraform Convergence

A fresh production Terraform plan was generated after the change.

Result:

`No changes. Your infrastructure matches the configuration.`

Detailed exit code:

`0`

Final Terraform footprint:

- Managed resources: 10
- Data sources: 1

Production therefore returned to zero Terraform drift.

---

## Post-Apply Convergence Evidence

Saved convergence plan:

`day33-post-tag-convergence.tfplan`

SHA256:

`69921c0f6f52dceba9a4fbf0450aa80f7436e14f586d6643d9375fe95fd3b73c`

Text evidence SHA256:

`f13fa1c59cb83003176963af0243b3b94ed2c419d81a47f11b76028513cad939`

JSON evidence SHA256:

`508c750d16fb94349a27deee89c809b1dbcb586c780f726d12fcc81c35afdd02`

---

## FinOps Architecture Decision

### Decision

Keep the existing S3 + CloudFront serverless architecture.

### Why

The workload is currently extremely small:

- approximately 137 viewer requests in 30 days
- approximately 451 KB transferred
- approximately 6.6 KB stored in S3
- two S3 objects

The existing architecture provides:

- private origin storage
- HTTPS public delivery
- CDN caching
- Terraform automation
- monitoring
- notifications
- low operational overhead
- usage-based cost characteristics

### Alternatives considered

#### EC2

Rejected for this workload because an always-on virtual machine would add
operational responsibility and cost without solving a current business need.

#### ECS/Fargate

Rejected for this workload because container orchestration is unnecessary for
a static website.

#### EKS/Kubernetes

Rejected because the workload does not require container scheduling,
multi-service orchestration, or Kubernetes capabilities.

#### Multi-region application architecture

Rejected because the current availability and workload requirements do not
justify the added cost and complexity.

#### CloudFront additional monitoring

Not enabled because the current standard metrics and alarm provide sufficient
visibility for the present workload.

---

## Cost Optimization Opportunities

Potential future optimizations should be driven by measured requirements.

Examples include:

1. Evaluate CloudFront price-class scope if visitor geography makes a narrower
   price class appropriate.
2. Review service-level billing if traffic or spend becomes material.
3. Activate relevant user-defined cost allocation tags in AWS Billing if
   detailed Cost Explorer allocation by tag is required.
4. Continue monitoring Budget alerts and service usage.
5. Avoid introducing persistent compute until application requirements
   actually require it.

---

## Cost Allocation Tag Follow-Up

Production resources now carry consistent governance tags.

AWS Billing cost-allocation-tag activation was not performed during this
change.

If tag-based billing reports are required later, the appropriate user-defined
tag keys should be reviewed and activated in the Billing console before using
them for detailed cost allocation.

---

## What Went Wrong and What Was Learned

### Problem

The first production tagging plan unexpectedly proposed an S3 bucket-policy
update.

### Root cause

The policy data source depended on managed resource attributes whose resources
had pending metadata changes.

Terraform therefore deferred policy evaluation, making the policy value
unknown during planning.

### Response

The plan was rejected instead of accepting the unexplained production write.

### Engineering improvement

An explicit existing CloudFront distribution ARN path was added for imported
production infrastructure.

This separated stable security identity from unrelated metadata changes.

### Result

The second plan contained exactly the intended two metadata updates and left
the bucket policy unchanged.

This demonstrates why production plans must be evaluated by resource and by
business intent rather than accepting a successful Terraform plan
automatically.

---

## Employer / Interview Explanation

A concise explanation of this work:

> I established a FinOps baseline for a Terraform-managed production static
> website on AWS. I measured the real workload, reviewed budget and account
> usage, and found the architecture was appropriately lightweight for the
> traffic level. I then standardized cost-attribution tags across S3 and
> CloudFront. During planning, Terraform unexpectedly wanted to rewrite the S3
> security policy because of a dependency on the CloudFront resource. I
> rejected that plan, traced the dependency, decoupled the stable production
> distribution ARN from metadata-only changes, added tests, passed CI, and
> applied a saved plan containing only two tag updates. I then verified the
> bucket policy, monitoring, website health, and zero Terraform drift.

---

## Day 33 Outcome

Day 33 is complete.

The production environment now has:

- a documented workload and cost baseline
- an active spending guardrail
- consistent workload governance tags
- improved future cost attribution
- tested policy-dependency handling
- a reviewed and checksummed production change
- preserved S3/CloudFront security boundaries
- healthy CloudFront delivery
- functioning CloudWatch monitoring
- zero Terraform drift

Most importantly, the architecture can now be defended in business terms:

**the current AWS design satisfies the workload's security, reliability,
operational, and cost requirements without introducing unjustified
infrastructure complexity.**
