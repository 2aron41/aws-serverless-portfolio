# Terraform Dev CloudFront Security Audit — August 5, 2026

## Goal

Verify that the development CloudFront and Origin Access Control setup keeps the S3 bucket private and uses narrowly scoped, least-privilege access.

## Terraform State

- CloudFront distribution in state: Yes
- Origin Access Control in state: Yes
- S3 bucket policy in state: Yes
- Final Terraform plan: No changes. Infrastructure matches configuration.

## CloudFront Checks

- Distribution enabled: Yes
- Default root object: `index.html`
- Origin points to S3 regional domain: Yes
- Viewer protocol policy: `redirect-to-https`
- Allowed methods: `GET`, `HEAD`, and `OPTIONS`
- HTTPS works: Yes, returned `HTTP/2 200`
- Distribution status: `Deployed`
- Price class: `PriceClass_100`

## Origin Access Control Checks

- OAC exists: Yes
- Signing behavior: `always`
- Signing protocol: `sigv4`
- Origin type: `s3`

## S3 Bucket Policy Checks

- Allows CloudFront service principal: Yes
- Allows only `s3:GetObject`: Yes
- Limits access to development bucket objects: Yes
- Restricts access using the CloudFront distribution ARN: Yes
- Does not allow public write: Yes
- Does not make the bucket public: Yes

## S3 Privacy Checks

- Block Public Access enabled: Yes
- `BlockPublicAcls`: `true`
- `IgnorePublicAcls`: `true`
- `BlockPublicPolicy`: `true`
- `RestrictPublicBuckets`: `true`
- S3 policy status reports public: No
- Direct S3 access blocked: Yes, returned `HTTP/1.1 403 Forbidden`
- CloudFront access works: Yes, returned `HTTP/2 200`
- Test object server-side encryption: `AES256`

## Production Resources Changed

No.

## Findings

The development CloudFront distribution is deployed and serves the encrypted test object successfully over HTTPS. Its origin uses the S3 regional endpoint and the configured Origin Access Control.

The S3 bucket policy grants the CloudFront service principal only `s3:GetObject` access to objects in the development bucket. Access is restricted by an `AWS:SourceArn` condition matching the development CloudFront distribution.

All four S3 Block Public Access settings are enabled, the bucket policy status reports `IsPublic` as `false`, and a direct request to the S3 object returns `403 Forbidden`.

A final saved Terraform plan reported no changes, confirming that the live development resources currently match the Terraform configuration.

## Fixes Needed

No security fixes are required.

The generated OAC name currently ends with a trailing hyphen. This is a minor naming-quality issue and does not affect security or functionality. It should be cleaned up during a later reviewed module change rather than modified during this audit.

## Lessons Learned

CloudFront can securely serve private S3 content without making the bucket public. OAC signs requests with SigV4, while the bucket policy restricts read access to one CloudFront distribution.

Real AWS verification is necessary because mocked Terraform tests cannot prove that the deployed distribution works, the bucket remains private, or the live bucket policy has the intended scope.

A final no-change plan provides evidence that the deployed infrastructure and Terraform configuration are synchronized.
