# Python Production Health Automation — August 11, 2026

## Day 35

## Objective

Build a Python/Boto3 production health checker for the AWS portfolio workload that verifies important operational and security conditions without modifying AWS resources.

The tool must:

- authenticate without hard-coded AWS credentials;
- fail closed if authenticated to the wrong AWS account;
- perform read-only AWS API calls;
- verify important S3, CloudFront, and CloudWatch conditions;
- perform public HTTP health checks;
- return useful process exit codes;
- be testable without AWS credentials;
- run automated tests in GitHub Actions.

## Business Context

### Business problem

The production portfolio site already has infrastructure as code, monitoring, alerting, security controls, and cost controls.

Important production conditions were still being checked manually with separate AWS CLI and HTTP commands. This was repetitive and harder to reuse consistently.

### Requirements

- Safe to run against production.
- No infrastructure mutations.
- Verify the expected AWS account before workload checks.
- Verify production health and security controls.
- Produce human-readable results.
- Produce machine-usable exit codes.
- Use temporary AWS login credentials.
- Be unit-testable without production AWS access.

### Constraints

- No production resource changes.
- No long-lived AWS access keys.
- No production AWS credentials in GitHub Actions.
- Keep the solution small and understandable.
- Do not introduce additional AWS infrastructure without a requirement.

### Decision

Use Python 3.12 with Boto3 for AWS API access and Python standard-library urllib functionality for HTTP checks.

Boto3 operations in the tool are read-only.

### Alternatives considered

An AWS CLI shell script would be quick but becomes harder to structure, mock, test, and extend as automation grows.

AWS Lambda could provide scheduled execution later, but Lambda, IAM, and scheduling infrastructure are not justified without a server-side scheduling requirement.

Existing CloudWatch monitoring already covers the current production 5xx requirement, so additional monitoring infrastructure was not needed.

## Python Environment

Local virtual environment:

```text
.venv/
```

Python version:

```text
Python 3.12.1
```

Tested dependencies:

```text
boto3==1.43.69
botocore==1.43.69
awscrt==0.36.0
s3transfer==0.19.2
```

Dependency declaration:

```text
boto3[crt]==1.43.69
```

The local .venv directory and generated Python bytecode are ignored by Git.

## Authentication Verification

AWS CLI and Boto3 authentication both succeeded against the expected production account.

```text
Expected account: 510497448584
Boto3 credential provider: login
```

No static AWS access key, secret access key, or session token was added to the repository.

## Production Health Tool

Implementation:

```text
scripts/aws_production_health.py
```

The tool is designed to perform read-only production verification.

Before workload checks begin, STS verifies that the authenticated AWS account matches the expected production account.

If the account does not match, the tool fails closed.

## Production Checks

### S3 bucket

Expected bucket:

```text
2aron41-aws-portfolio-20260713
```

The tool verifies authenticated read access to the expected bucket.

### S3 Block Public Access

The tool verifies that all four bucket-level controls are enabled:

```text
BlockPublicAcls
IgnorePublicAcls
BlockPublicPolicy
RestrictPublicBuckets
```

### S3 governance tags

Required production tags:

```text
Project=aws-serverless-portfolio
Environment=prod
ManagedBy=Terraform
Owner=2aron41
Purpose=Production portfolio website
```

### CloudFront distribution

Expected distribution:

```text
EUWNERX790PYN
```

Required health conditions:

```text
Status=Deployed
Enabled=true
```

### CloudFront governance tags

The tool verifies the required production governance tags and the existing CloudFront Name tag.

### CloudWatch 5xx alarm

The health condition requires:

```text
StateValue=OK
ActionsEnabled=true
```

### Public CloudFront endpoint

Expected production domain:

```text
d1wnw5kep14m5j.cloudfront.net
```

Expected public response:

```text
HTTP 200
```

### Direct S3 access

The tool makes an unauthenticated request directly to the S3 object endpoint.

Expected response:

```text
HTTP 403
```

This verifies that the S3 origin remains private from direct public access.

## Live Production Result

The Day 35 live execution completed successfully.

```text
Overall production health: PASS
Health exit code: 0
```

No AWS write operation was performed.

## Exit-Code Contract

The health checker defines the following process outcomes:

```text
0 = healthy production
1 = one or more health checks failed
2 = fatal credential or identity failure
```

### Exit code 0

Live production validation returned:

```text
0
```

Result: PASS.

### Exit code 1

A local simulation injected a failed production health check.

```text
Simulated health-failure exit code: 1
```

Result: PASS.

### Exit code 2

A local simulation authenticated the program to the wrong account:

```text
000000000000
```

Observed result:

```text
Simulated wrong-account exit code: 2
```

Result: PASS.

The wrong-account test demonstrates that the tool fails closed before performing production workload checks.

## Automated Testing

Test implementation:

```text
tests/test_aws_production_health.py
```

The test suite uses mocks and local simulations rather than production AWS resources.

Coverage includes:

- required governance-tag success and failure;
- S3 Block Public Access success and failure;
- CloudFront deployed/enabled success and disabled failure;
- healthy CloudWatch alarm and ALARM failure;
- CloudFront HTTP 200 verification;
- direct S3 HTTP 403 verification;
- detection of unexpectedly public S3 content;
- unexpected exception handling;
- main() healthy exit code 0;
- main() health-failure exit code 1;
- missing-credential exit code 2;
- wrong-account exit code 2.

Final local result:

```text
Ran 16 tests
OK
```

Final test status:

```text
16/16 PASS
```

## Read-Only Security Review

Observed AWS SDK operations in the production health tool:

```text
describe_alarms
get_bucket_tagging
get_caller_identity
get_distribution
get_public_access_block
head_bucket
list_tags_for_resource
```

The static review found no AWS SDK write-style operations.

No hard-coded AWS credential material was detected in the production health tool, unit tests, or dependency declaration.

## Repository Hygiene

The local Python virtual environment is ignored:

```text
.venv/
```

Generated Python artifacts are ignored:

```text
__pycache__/
*.py[cod]
```

This prevents local environments and generated bytecode from entering version control.

## GitHub Actions

Workflow:

```text
.github/workflows/python-production-health-tests.yml
```

Workflow name:

```text
Python Production Health Tests
```

The workflow performs:

1. repository checkout;
2. Python 3.12 setup;
3. dependency installation;
4. Python syntax validation;
5. production-health unit tests.

Repository permission:

```text
contents: read
```

AWS credentials are not configured in this workflow.

The CI runner therefore validates the application logic without receiving production AWS access.

## GitHub Actions Verification

Verified workflow run:

```text
Run ID: 31558336581
Job ID: 93995232750
Workflow: Python Production Health Tests
Branch: main
Event: push
Head SHA: 85a2d7f182eff130474cef2a8fbd18b885729798
Status: completed
Conclusion: success
Job duration: 13 seconds
```

Successful CI stages included:

```text
Checkout repository
Set up Python
Install dependencies
Python syntax check
Run production health unit tests
```

## Git Evidence

Python production health checker:

```text
d993155 Add read-only production health checker
```

Python CI workflow:

```text
85a2d7f Add Python production health tests to CI
```

## Production Change Summary

```text
AWS infrastructure changes: NONE
AWS write operations: NONE
Terraform plan: NOT RUN
Terraform apply: NOT RUN
```

Production remained healthy during live verification.

## Tradeoffs

### Workload identifiers are currently project-specific

The first implementation keeps the production account, bucket, distribution, domain, alarm, and expected tags directly in the script.

This makes the implementation explicit and easy to understand, but it limits reuse across other environments.

Command-line arguments, environment variables, or configuration files can be introduced later if multi-environment reuse becomes a real requirement.

### CI does not run live production checks

GitHub Actions validates the program with mocks and receives no AWS production credentials.

This trades live CI integration testing for stronger credential isolation.

Live production verification is performed from an authenticated operator environment.

### Terraform remains configuration source of truth

The Python tool checks important operational conditions but does not reproduce every Terraform configuration assertion.

Terraform remains the source of truth for exact infrastructure configuration and drift management.

## Outcome

Before Day 35, production verification depended primarily on separate AWS CLI and HTTP commands.

After Day 35, the repository contains a reusable read-only Python health checker that verifies account identity, S3 security, governance tags, CloudFront deployment health, CloudWatch alarm health, public HTTP availability, and blocked direct S3 access.

The tool has deterministic automation exit codes, 16 automated tests, and a GitHub Actions workflow that validates the code without production AWS credentials.

This improves repeatability while avoiding unnecessary infrastructure or production permissions.

## Day 35 Status

```text
Python/Boto3 environment:             COMPLETE
AWS login credential integration:    VERIFIED
Wrong-account fail-closed control:    VERIFIED
Read-only production health checker: COMPLETE
Live production health:              PASS
Exit code 0:                          VERIFIED
Exit code 1:                          VERIFIED
Exit code 2:                          VERIFIED
Unit tests:                           16/16 PASS
GitHub Actions Python CI:             SUCCESS
AWS credentials in CI:               NONE
AWS infrastructure changes:          NONE
AWS writes:                           NONE
Terraform plan/apply:                 NOT RUN
```
