# Terraform Dev CloudFront/OAC Evidence — August 4, 2026

## Goal

Verify that CloudFront, Origin Access Control (OAC), and the supporting private S3 configuration are enabled in the development Terraform environment only.

## Pre-Change Safety

* AWS identity verified: Yes (`arn:aws:iam::510497448584:user/aaron-admin`)
* AWS Region: `us-east-1`
* Environment: `dev`
* Remote state initialized: Yes
* Remote backend: S3 with `use_lockfile = true`
* State backup created: Yes
* State backup path: `/workspaces/terraform-state-backups/day-23-before-dev-cloudfront.json`
* Production resources changed: No

## Dev Configuration

* `enable_cloudfront = true` is configured in the ignored development `terraform.tfvars` file.
* The configuration applies only to the development environment.

## Terraform Apply

Applied saved plan:

`terraform apply day-23-outputs.tfplan`

Result:

`Apply complete! Resources: 0 added, 0 changed, 0 destroyed.`

This apply did not create, modify, or destroy any Terraform-managed resources. It confirmed that the infrastructure represented by the saved plan already matched the deployed development environment.

## Verified Terraform Outputs

* `aws_region = "us-east-1"`
* `environment = "dev"`
* `project_name = "aws-serverless-portfolio"`
* `dev_bucket_name = "aws-serverless-portfolio-dev-2aron41-8ab73efa81e3bceff8c0a3d066"`
* `cloudfront_distribution_id = "EBPB0D0F7AVMX"`
* `cloudfront_domain_name = "d2z14ubddi45aa.cloudfront.net"`
* `cloudfront_oac_id = "E36HY1D4F1XHZC"`

## CloudFront/OAC Verification

* CloudFront distribution present: Yes
* CloudFront distribution ID: `EBPB0D0F7AVMX`
* CloudFront domain available: Yes
* CloudFront domain: `d2z14ubddi45aa.cloudfront.net`
* Origin Access Control present: Yes
* Origin Access Control ID: `E36HY1D4F1XHZC`
* CloudFront resources exposed through Terraform outputs: Yes

## S3 Security Verification

* Development S3 bucket remains private: Yes
* S3 Block Public Access should remain enabled.
* Direct public S3 access should remain blocked.
* CloudFront should access the private bucket through OAC.
* S3 bucket-policy presence was not independently demonstrated by the provided output and should be verified through Terraform state or AWS before being recorded as confirmed.

Recommended verification commands:

```bash
terraform state list | grep -E 'cloudfront|origin_access_control|bucket_policy'
```

```bash
aws s3api get-bucket-policy \
  --bucket aws-serverless-portfolio-dev-2aron41-8ab73efa81e3bceff8c0a3d066
```

## Stop Conditions Checked

* S3 bucket replacement proposed: No
* Resource destruction: None
* Public bucket access introduced: No
* Production resources changed: No
* IAM resources changed: None observed
* DNS resources changed: None observed
* CloudFront resources destroyed or replaced: No

## Final Verification

* Terraform apply result: `0 added, 0 changed, 0 destroyed`
* CloudFront distribution output exists: Yes
* CloudFront domain output exists: Yes
* OAC output exists: Yes
* Development bucket output exists: Yes
* Production resources changed: No

## Problems Encountered

* The earlier evidence document no longer matched the actual Terraform state and outputs.
* It incorrectly stated that the CloudFront distribution and OAC were unavailable.
* It incorrectly stated that the saved Day 23 plan was unavailable, even though `day-23-outputs.tfplan` was successfully applied.
* The bucket policy still requires separate verification before it can be documented as confirmed.

## Fixes

* Applied the saved `day-23-outputs.tfplan`.
* Ran `terraform output`.
* Recorded the verified CloudFront distribution ID.
* Recorded the verified CloudFront domain name.
* Recorded the verified OAC ID.
* Updated the evidence to distinguish verified results from items that still require confirmation.

## Lessons Learned

* Evidence documents must be updated after later Terraform operations change what has been verified.
* A `No changes` result does not mean that a resource is absent; it means the deployed infrastructure already matches the Terraform configuration represented by the plan.
* Terraform outputs can verify that resources exist without those resources being newly created during the latest apply.
* Resource creation and resource verification are different events and should be documented separately.
* The S3 bucket policy should not be marked as verified until it is confirmed through Terraform state, a Terraform plan, or the AWS API.

