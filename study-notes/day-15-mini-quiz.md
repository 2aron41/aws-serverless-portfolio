# Day 15 Mini Quiz

## 1. Why should reusable Terraform modules have input validation?

Input validation rejects invalid or incomplete values before they can produce unsafe plans or provider errors.

## 2. What does a module output provide?

A module output exposes useful information from resources inside the module so the calling configuration or another module can reference it.

## 3. Why is production import risky?

An incorrect resource address or mismatched configuration could cause Terraform to propose changing, replacing, or destroying an existing production resource.

## 4. Why should Terraform code match real infrastructure before import?

After import, Terraform compares the real resource with the code. Differences can create unexpected change proposals.

## 5. Why should CloudFront not be imported until its configuration is understood?

CloudFront has important settings involving origins, cache behavior, certificates, access control, and distribution behavior. Incorrect code could disrupt the live website.

## 6. What should a clean Terraform plan show before production migration?

It should show only the expected import or state-tracking result and no unexpected additions, changes, replacements, or destroys.

## 7. Why should website uploads remain in GitHub Actions?

Website content changes more frequently than infrastructure. GitHub Actions is better suited for validating, synchronizing, and deploying those files.

## 8. Why should the production rollback plan be written before importing?

A written rollback plan provides reviewed recovery steps before a problem occurs and prevents rushed state or infrastructure changes.

## 9. What is the difference between a dev module refactor and production migration?

The dev refactor moved resources already tracked by Terraform into a module. Production migration would bring manually created live resources under Terraform management for the first time.

## 10. What would make you stop immediately before applying Terraform?

I would stop for any unexpected production change, resource destruction, replacement, duplicate resource, weaker access control, IAM expansion, or unexplained plan action.
