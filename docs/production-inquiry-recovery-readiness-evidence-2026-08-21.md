# Production Inquiry Recovery Readiness Evidence — August 21, 2026

## Purpose

Day 44 evaluated the production inquiry service's real recovery capabilities
and expanded the existing production incident runbook with a concrete recovery
decision procedure.

The goal was to document recovery methods that are actually supported by the
current architecture rather than assuming rollback capabilities that do not
exist.

No production failure was intentionally created.

## Starting Baseline

Day 44 began from:

- repository clean and synchronized
- production Terraform state: 30 objects
- Terraform validation: successful
- Terraform convergence: no changes
- Lambda Errors alarm: OK
- Lambda Throttles alarm: OK
- API Gateway 5xx alarm: OK
- API Gateway 4xx alarm: OK
- all four inquiry alarm actions enabled

No Terraform apply was required.

## Authentication Recovery

The initial production state inspection failed because the AWS CLI login
session had expired.

The failed command was not treated as a real zero-object state.

AWS authentication was restored and verified against account:

`510497448584`

After authentication recovery:

- Terraform backend access succeeded
- production state was confirmed at 30 objects
- Terraform validation succeeded
- Terraform convergence returned detailed exit code 0

This reinforced that failed upstream commands must not be interpreted as valid
infrastructure measurements.

## Recovery Capability Audit

Day 44 performed a read-only audit of:

- Git history
- existing recovery documentation
- production Terraform backend
- backend S3 protection
- Lambda deployment configuration
- Lambda versions and aliases
- API Gateway deployment behavior
- production site-bucket versioning status
- prior partial-apply recovery evidence
- current operational alarm health

## Terraform Backend Recovery Protection

Production Terraform uses an S3 backend:

- bucket: `cloud-ai-roadmap-terraform-state-510497448584-us-east-1`
- key: `aws-serverless-portfolio/prod/terraform.tfstate`
- region: `us-east-1`
- encryption enabled
- lockfile enabled

Backend bucket verification showed:

- S3 versioning: enabled
- server-side encryption: AES256

This provides state-version history for recovery if Terraform state itself is
damaged or lost.

State restoration is documented as a last-resort operation requiring separate
review.

An undesirable infrastructure change alone is not a reason to restore an old
Terraform state version.

## Lambda Recovery Capability

The production inquiry Lambda currently uses:

- function: `aws-serverless-portfolio-prod-inquiry`
- runtime: Python 3.12
- state: Active
- last update status: Successful
- deployed version: `$LATEST`
- Terraform `publish`: false

Audit results:

- published Lambda versions: none beyond `$LATEST`
- Lambda aliases: none

Therefore instant alias-based Lambda rollback is not currently supported.

The supported application recovery method is:

Git last-known-good state
→ restore or revert required code
→ local tests
→ commit
→ push
→ CI
→ fresh production saved Terraform plan
→ inspect exact mutations
→ apply only the reviewed saved plan
→ live verification
→ alarm verification
→ Terraform convergence

Manual Lambda code replacement outside Terraform is not the normal recovery
method because it would introduce infrastructure drift.

## Terraform Configuration Recovery

The documented recovery method for a bad Terraform configuration is:

1. identify the last known-good desired state
2. restore or revert only the defective configuration
3. run formatting, validation, and relevant tests
4. commit and push
5. verify CI
6. create a fresh saved production plan
7. inspect every planned mutation
8. stop on unexpected additions, replacements, or destruction
9. apply only the exact reviewed saved plan
10. verify live AWS resources
11. verify Terraform convergence

A Git revert by itself does not change production infrastructure.

## Partial Apply Recovery

Existing production history contains a real partial-apply recovery example.

During the original inquiry production deployment, AWS rejected a Lambda
reserved-concurrency configuration after several resources had already been
created.

The recovery process:

- inspected live AWS resources
- inspected Terraform state
- identified the failed concurrency setting
- corrected desired state
- updated tests
- verified the live Lambda was healthy
- removed the taint only after verification
- created a fresh recovery plan
- verified the Lambda had no planned replacement or destruction
- applied only the remaining reviewed work
- verified final Terraform convergence

Day 44 incorporated this pattern into the incident runbook.

The runbook now explicitly states:

`Do not blindly rerun the original failed apply.`

## API Gateway Recovery Model

The production HTTP API uses:

- API ID: `2v4ijd6eta`
- stage: `$default`
- automatic deployment: enabled
- route: `POST /inquiries`

There is no separately managed manual deployment-promotion layer in the
current architecture.

API Gateway recovery should therefore use reviewed Terraform desired state
rather than assuming a previous deployment identifier is the primary rollback
mechanism.

## Production Site Bucket Recovery Observation

The production website bucket versioning inspection did not report an enabled
versioning state during the Day 44 audit.

Therefore Day 44 does not assume that website content has S3 object-version
rollback protection.

This is distinct from the Terraform backend bucket, whose versioning was
explicitly verified as enabled.

## Monitoring Recovery

Operational alarms should not be manually forced to `OK` during a real
incident.

Recovery requires fixing the underlying failure or traffic condition and
allowing CloudWatch to reevaluate the real metric.

Post-recovery verification includes:

- alarm returns to OK
- service health confirmed
- application behavior validated if necessary
- Terraform convergence confirmed
- recovery notification confirmed
- incident timeline recorded
- root cause and remediation documented

## Recovery Stop Conditions

The incident runbook now requires recovery to stop if:

- AWS account or environment cannot be verified
- failure domain is still unknown
- repository contains unrelated changes
- Terraform state does not match the expected environment
- a plan contains unexplained additions
- a plan contains unexpected replacement
- a plan contains unexpected destruction
- a saved plan differs from the reviewed artifact
- the proposed action weakens validation, throttling, IAM, monitoring,
  S3 privacy, or another safety control
- the proposed action depends on hiding or manually clearing a real alarm

Explicit prohibitions:

- do not use `terraform destroy` as rollback
- do not make the production S3 bucket public as a recovery shortcut

## Runbook Change

Updated:

`docs/inquiry-incident-runbook.md`

Commit:

`9e534d3cb43f111febc7281db2a7b6cf66475875`

Commit message:

`Add inquiry recovery procedure`

Commit result:

- 1 file changed
- 174 insertions
- 4 deletions

The runbook now contains:

- Recovery Decision Procedure
- incident baseline procedure
- Lambda/application recovery
- Terraform regression recovery
- partial-apply recovery
- Terraform state recovery
- API Gateway recovery
- monitoring recovery
- recovery stop conditions
- Post-Recovery Verification

## AWS Impact

Day 44 production configuration changes:

`0`

Terraform files changed:

`0`

Terraform apply performed:

`no`

Production requests generated:

`0`

No Lambda configuration was changed.

No API Gateway configuration was changed.

No CloudWatch configuration was changed.

No SNS configuration was changed.

No Terraform state was restored or modified.

## Final Result

Day 44 established a concrete recovery model for the production serverless
inquiry service.

Final status:

- production state: 30 objects
- Terraform: converged
- Lambda rollback capabilities: audited
- Lambda alias rollback: not currently available
- Terraform backend versioning: verified
- partial-apply recovery: documented
- API Gateway recovery model: documented
- monitoring recovery: documented
- recovery stop conditions: documented
- post-recovery verification: documented
- incident runbook: updated and committed
- production changes: 0
