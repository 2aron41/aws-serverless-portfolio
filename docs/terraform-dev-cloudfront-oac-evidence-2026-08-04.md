# Terraform Dev CloudFront/OAC Evidence — August 4, 2026

## Goal

Verify that CloudFront, Origin Access Control (OAC), the private S3 bucket policy, and private content delivery are enabled in the development Terraform environment only.

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

```bash
terraform apply day-23-outputs.tfplan
```

Result:

```text
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

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
* CloudFront deployment status: `Deployed`
* CloudFront domain available: Yes
* CloudFront domain: `d2z14ubddi45aa.cloudfront.net`
* Origin Access Control present: Yes
* Origin Access Control ID: `E36HY1D4F1XHZC`
* CloudFront resources exposed through Terraform outputs: Yes

## CloudFront Content Verification

* CloudFront distribution ID: `EBPB0D0F7AVMX`
* CloudFront domain: `d2z14ubddi45aa.cloudfront.net`
* CloudFront deployment status: `Deployed`
* Origin Access Control ID: `E36HY1D4F1XHZC`
* Development test object: `index.html`
* Test object server-side encryption: `AES256`
* Initial CloudFront request: `HTTP/2 403`
* Initial response source: Amazon S3 through CloudFront
* Initial CloudFront cache result: `Error from cloudfront`
* Initial result: The CloudFront distribution was reachable, but successful delivery of the test object had not yet been verified.
* Test page uploaded to the private development S3 bucket: Yes
* Final CloudFront request: `HTTP/2 200`
* Response content type: `text/html`
* Final CloudFront cache result: `Miss from cloudfront`
* Test page successfully delivered through CloudFront and OAC: Yes
* Direct public S3 access enabled: No

The final `HTTP/2 200` response confirms that CloudFront successfully retrieved and delivered `index.html` from the private development S3 bucket through OAC.

The `Miss from cloudfront` result means the object was retrieved from the S3 origin instead of being served from the CloudFront cache during that request.

## S3 Security Verification

* Development S3 bucket remains private: Yes
* Direct public S3 access enabled: No
* Test object encryption: `AES256`
* S3 bucket policy present in Terraform state: Yes
* Terraform address: `module.static_site.aws_s3_bucket_policy.cloudfront[0]`
* CloudFront accesses the private S3 bucket through OAC: Yes
* Test object successfully delivered through CloudFront: Yes
* Final CloudFront response: `HTTP/2 200`

The Terraform state confirms that the CloudFront-specific S3 bucket policy is managed at:

```text
module.static_site.aws_s3_bucket_policy.cloudfront[0]
```

Combined with the successful CloudFront response and the absence of direct public S3 access, this verifies that the private development bucket can deliver content through CloudFront and OAC.

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
* CloudFront distribution present: Yes
* CloudFront deployment status: `Deployed`
* CloudFront distribution output exists: Yes
* CloudFront domain output exists: Yes
* OAC output exists: Yes
* Development bucket output exists: Yes
* S3 bucket policy present in Terraform state: Yes
* S3 bucket policy Terraform address: `module.static_site.aws_s3_bucket_policy.cloudfront[0]`
* CloudFront distribution reachable: Yes
* Initial CloudFront HTTP result: `HTTP/2 403`
* Final CloudFront HTTP result: `HTTP/2 200`
* Successful delivery of `index.html`: Yes
* Response content type: `text/html`
* Test object encryption: `AES256`
* Direct public S3 access enabled: No
* Production resources changed: No

## Problems Encountered

* The earlier evidence document did not match the actual Terraform state and outputs.
* It incorrectly stated that the CloudFront distribution and OAC were unavailable.
* It incorrectly stated that the saved Day 23 plan was unavailable, even though `day-23-outputs.tfplan` was successfully applied.
* The initial CloudFront request returned `HTTP/2 403`.
* The initial response came from Amazon S3 through CloudFront.
* The initial CloudFront cache result was `Error from cloudfront`.
* The distribution was reachable, but successful delivery of `index.html` had not yet been verified.

## Fixes

* Applied the saved `day-23-outputs.tfplan`.
* Ran `terraform output`.
* Recorded the verified CloudFront distribution ID.
* Recorded the verified CloudFront domain name.
* Recorded the verified OAC ID.
* Confirmed that the CloudFront distribution status was `Deployed`.
* Recorded the initial `HTTP/2 403` response.
* Uploaded the `index.html` test page to the private development S3 bucket.
* Confirmed that the test object uses `AES256` server-side encryption.
* Retested the CloudFront domain.
* Received a final `HTTP/2 200` response.
* Confirmed the response content type was `text/html`.
* Confirmed the CloudFront cache result was `Miss from cloudfront`.
* Confirmed that the S3 bucket policy exists in Terraform state.
* Recorded the bucket-policy Terraform address as `module.static_site.aws_s3_bucket_policy.cloudfront[0]`.
* Confirmed that direct public S3 access was not enabled.
* Updated the evidence to distinguish the initial failure from the final successful verification.

## Lessons Learned

* Evidence documents must reflect verified Terraform and AWS results rather than expected outcomes.
* A Terraform result of `0 added, 0 changed, 0 destroyed` does not mean that the resources are absent. It means the deployed infrastructure already matches the saved Terraform plan.
* Terraform outputs can verify that resources exist even when the latest apply does not create or modify them.
* Resource creation, resource reachability, and successful content delivery are separate verification steps.
* An HTTP `403` response through CloudFront can confirm that the distribution is reachable, but it does not confirm successful website delivery.
* A final HTTP `200` response confirms that the requested content was successfully delivered.
* A `Miss from cloudfront` response means CloudFront retrieved the object from its origin instead of serving a cached copy.
* Terraform state can be used to confirm that a resource, such as the private S3 bucket policy, is managed by Terraform.
* The private S3 bucket can serve content through CloudFront and OAC without enabling direct public S3 access.
* Production resources should remain isolated from development infrastructure changes.

