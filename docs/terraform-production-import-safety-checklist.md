# Terraform Production Import Safety Checklist

## Rule

No production import or apply unless every safety gate is complete.

## Safety Gates

### 1. Inventory complete

- Production S3 bucket: Identify the exact bucket name, ARN, region, tags, and current purpose.
- S3 Block Public Access: Record all four current Block Public Access settings.
- S3 versioning: Record whether versioning is enabled, suspended, or unconfigured.
- S3 encryption: Record the current server-side encryption algorithm and configuration.
- CloudFront distribution: Record the distribution ID, ARN, domain name, status, aliases, origins, cache behaviors, certificate settings, price class, logging, restrictions, and tags.
- Origin Access Control: Record the OAC ID, name, origin type, signing behavior, and signing protocol.
- S3 bucket policy: Save and review the current policy, principals, actions, resources, and conditions.
- IAM OIDC provider: Record the provider ARN, URL, client IDs, and thumbprint configuration.
- IAM deployment role: Record the role ARN, trust policy, tags, and session settings.
- IAM permissions policy: Record all managed and inline policies attached to the deployment role.

### 2. Terraform code matches real infrastructure

- S3: Terraform configuration must reflect the real bucket name, versioning, encryption, public-access protections, tags, and lifecycle settings.
- CloudFront: Terraform configuration must match the existing origins, cache behaviors, default root object, HTTPS settings, certificate, aliases, restrictions, price class, and logging configuration.
- OAC: Terraform configuration must match the existing OAC name, description, origin type, signing behavior, and signing protocol.
- IAM: Terraform configuration must match the existing OIDC provider, role trust relationship, permissions, tags, and policy attachments.

No resource should be imported until its Terraform configuration closely matches the real AWS resource.

### 3. State safety

- Remote backend: Confirm the correct backend bucket, key, region, workspace, encryption, and access permissions before running any import.
- Pre-import state backup: Create and store a timestamped state backup outside the repository before the first production import.
- State-locking understood: Confirm how concurrent Terraform operations are prevented or controlled. Ensure no other Terraform operation is running during import.

### 4. Import commands prepared

Prepare each command in advance, but do not run it until the matching code and safety gates are complete.

- S3 bucket: Prepare the exact module resource address and bucket identifier.
- Public access block: Prepare the resource address and bucket identifier.
- Versioning: Prepare the resource address and bucket identifier required by the AWS provider.
- Encryption: Prepare the resource address and bucket identifier required by the AWS provider.
- CloudFront: Prepare the distribution resource address and distribution ID.
- OAC: Prepare the OAC resource address and OAC ID.
- IAM: Prepare the provider, role, policy, and policy-attachment resource addresses and identifiers.

Verify every import identifier against the current AWS provider documentation before use.

### 5. Plan expectations written

Expected safe result:

After each import, Terraform should recognize the existing resource without proposing destruction or replacement.

Small in-place differences may appear when Terraform configuration does not yet match optional or provider-normalized settings. Every difference must be understood before continuing.

The final safe production plan should show:

- No resource destruction
- No unexpected replacement
- No public S3 access
- No removal of Block Public Access
- No removal of encryption
- No removal of versioning
- No unintended CloudFront origin or cache behavior changes
- No certificate, alias, DNS, or domain changes
- No weakening of OAC or the S3 bucket policy
- No weakening of the GitHub OIDC trust policy
- No broader IAM permissions
- No unexplained tag removal
- Ideally: `No changes`

### 6. Stop conditions

Stop immediately if Terraform proposes:

- Destroying production resources
- Replacing CloudFront
- Making S3 public
- Disabling any S3 Block Public Access setting
- Removing OAC
- Allowing the wrong CloudFront distribution to access S3
- Weakening the IAM trust policy
- Broadening IAM permissions unexpectedly
- Removing encryption
- Suspending or removing versioning unexpectedly
- Removing required tags
- Changing the CloudFront certificate
- Changing aliases, DNS, or custom domain settings unexpectedly
- Changing cache behavior or origin settings without a reviewed reason
- Modifying resources outside the approved import scope

### 7. Rollback procedure

If the plan is unsafe:

- Do not apply.
- Save the plan output as evidence.
- Identify whether the difference comes from incorrect code, the wrong import address, missing configuration, provider normalization, or real infrastructure drift.
- Revert or correct the Terraform code.
- Re-run `terraform fmt`, `terraform validate`, and the relevant tests.
- Re-run the production plan.
- Check Terraform state before removing or changing any state entry.
- Use `terraform state rm` only when the imported address is proven incorrect and no infrastructure change will occur.
- Restore the state backup only if state has been damaged and the restoration procedure has been reviewed.
- Re-check the live website and AWS configuration after any state recovery.
- Never use an apply operation as a shortcut to make an unexplained plan disappear.
