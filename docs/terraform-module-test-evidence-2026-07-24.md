# Terraform Module Test Evidence — July 24, 2026

## Goal

Validate the static-site Terraform module before reusing it for more environments.

## Tests Attempted

- Valid module input test: Passed
- Empty bucket name test: Passed by rejecting the invalid value
- Invalid uppercase bucket name test: Passed by rejecting the invalid value
- Invalid environment test: Passed by rejecting `staging`
- Missing required tag test: Passed by rejecting the incomplete tag map

## Commands Run

- terraform fmt: `terraform fmt -recursive`
- terraform init: `terraform init -backend=false`
- terraform validate: `terraform validate`
- terraform test: `terraform test -no-color`
- final dev plan: `terraform plan -no-color`

## Results

- Terraform test exit code: `0`
- Tests passed: `5`
- Tests failed: `0`
- Module validation: Success
- Final dev plan exit code: `0`
- Final dev plan: `No changes. Your infrastructure matches the configuration.`

The valid-input test confirmed:

- The sample bucket name was accepted.
- The `dev` environment was accepted.
- All five required tags were supplied.
- Versioning resolved to `Enabled`.
- All four S3 public-access protections remained enabled.

The expected-failure tests confirmed:

- An empty bucket name is rejected.
- A bucket name containing uppercase letters is rejected.
- The unsupported `staging` environment is rejected.
- A tag map missing `Purpose` is rejected.

## Problems Encountered

- The first final-plan summary returned no output because the AWS region was not set.
- AWS identity was verified explicitly with the `us-east-1` region.
- The module test initialization generated a module-level dependency lock file.

## Fixes

- Exported or specified the `us-east-1` AWS region.
- Verified the `aaron-admin` identity before rerunning the dev plan.
- Ran tests from the static-site module root.
- Used a mocked AWS provider and `command = plan`.
- Used `expect_failures` for invalid inputs.

## Lessons Learned

- `terraform validate` checks whether the configuration is structurally valid.
- `terraform test` executes test runs and evaluates assertions.
- Expected-failure tests prove that validation rejects known bad inputs.
- Mocked providers allow module tests without creating AWS resources.
- Passing module tests do not replace a real plan against the dev state.
- A clean final dev plan is still required before accepting a module change.

## Production Resources Changed

No.
