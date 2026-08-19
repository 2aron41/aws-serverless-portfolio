# Production Inquiry Cooldown Evidence — August 17, 2026

## Objective

Add lightweight duplicate-submission protection to the production portfolio inquiry form without changing the API contract or backend infrastructure.

The protection reduces accidental rapid repeat submissions while preserving normal inquiry behavior.

## Implementation

The production frontend now implements a 30-second in-memory submission cooldown.

Implementation properties:

- cooldown duration: 30 seconds
- state is held only in JavaScript memory
- cooldown begins only after a successful API submission
- failed HTTP requests do not start the cooldown
- network failures do not start the cooldown
- submissions are allowed again after the cooldown expires
- no localStorage is used
- no sessionStorage is used
- no cookies are used for cooldown state
- the inquiry API endpoint is unchanged
- the inquiry payload remains exactly:
  - name
  - email
  - message

Because the cooldown is intentionally memory-only, refreshing the page, reopening the page, or using another browser context resets the frontend cooldown.

This is lightweight accidental-duplicate protection, not a server-side security boundary or complete abuse-prevention mechanism.

## Test-First Development

Day 39 used a red/green test-first workflow.

### Red Phase

A new frontend test was added before the production implementation.

The test verified that an immediate second submission after a successful inquiry must not make another API request.

Before implementation, the test failed as expected because the second submission reached the API.

Observed failure:

    Immediate duplicate submission must not call the API again.

    2 !== 1

This demonstrated that the test detected the missing behavior before production code was changed.

### Green Phase

The frontend implementation added:

    const SUBMISSION_COOLDOWN_MS = 30_000;
    let lastSuccessfulSubmissionAt = null;

Before sending a valid request, the frontend checks whether the most recent successful submission occurred less than 30 seconds earlier.

During the cooldown, the user receives:

    Please wait before sending another message.

After a successful request:

    lastSuccessfulSubmissionAt = Date.now();

The timestamp is not set for failed requests.

## Frontend Test Coverage

The frontend test suite was expanded from 5 tests to 8 tests.

Verified behaviors:

1. native invalid form blocks fetch
2. trimmed invalid values block fetch
3. successful submission trims payload and resets form
4. immediate duplicate submission is blocked
5. submission is allowed after cooldown expires
6. failed submission does not start cooldown
7. HTTP failure returns generic UI error
8. network failure returns generic UI error

Final local result:

    Success! 8 passed, 0 failed.

The complete website validator also passed.

## CI Verification

Day 39 frontend commit:

    cc738475889a6f3280e2fb60d63c330802be0006

Commit message:

    Add inquiry submission cooldown

Website CI run:

    31989415034

CI verified:

- exact Day 39 commit
- all 8 frontend tests
- website validation

Result:

    Success! 8 passed, 0 failed.
    Website validation passed.

CI conclusion:

    success

## Deployment Safety Investigation

Two manual deployment attempts for the Day 39 commit intentionally entered the workflow's controlled failure path because the `run_failure_test` input was enabled.

Failed deployment runs:

    31989914744
    31990129391

The second failure was inspected in detail.

The workflow stopped at:

    Controlled failure exercise

Observed message:

    Intentional Day 8 failure test.
    PASS: Workflow stopped before AWS authentication or deployment.

The following deployment steps were skipped:

- repository checkout
- website validation
- frontend inquiry test
- AWS OIDC authentication
- AWS identity verification
- S3 synchronization preview
- S3 deployment
- CloudFront invalidation
- live CloudFront verification

Therefore, the controlled failures did not deploy or modify production AWS resources.

## Successful Production Deployment

A new manual workflow dispatch was started with the controlled failure input disabled.

Successful deployment run:

    31990458959

Deployment commit:

    cc738475889a6f3280e2fb60d63c330802be0006

Result:

    success

Verified successful steps included:

- main-branch deployment gate
- repository checkout
- website validation
- frontend inquiry behavior tests
- AWS authentication through GitHub OIDC
- S3 synchronization
- production S3 deployment
- CloudFront cache invalidation
- live CloudFront deployment verification
- direct S3 access verification

The controlled failure exercise was correctly skipped.

## Live Asset Verification

The deployed CloudFront `app.js` was downloaded after deployment.

Live production markers verified:

    const SUBMISSION_COOLDOWN_MS = 30_000;
    let lastSuccessfulSubmissionAt = null;
    Please wait before sending another message.
    lastSuccessfulSubmissionAt = Date.now();

Repository `website/app.js` SHA256:

    8f3e1e2c6a86f6a948ec096daed576f649bbe65b88e4eefe18ec8885e9ff5171

Live CloudFront `app.js` SHA256:

    8f3e1e2c6a86f6a948ec096daed576f649bbe65b88e4eefe18ec8885e9ff5171

The files matched exactly.

## Production Security Baseline

Post-deployment verification showed:

    CloudFront HTTP: 200
    Direct S3 HTTP: 403

Therefore:

- the production website remained available through CloudFront
- the S3 origin remained inaccessible directly
- the existing private-origin security boundary remained intact

## Controlled Browser Validation

The production inquiry form was tested manually in the same loaded browser page.

### First Submission

A valid controlled inquiry was submitted.

Result:

- submission succeeded
- success UI was displayed
- the form reset
- the inquiry notification path worked

### Immediate Second Submission

The form was refilled and submitted again within the 30-second cooldown.

Production displayed:

    Please wait before sending another message.

Result:

- immediate duplicate submission was blocked by the frontend cooldown

### Post-Cooldown Submission

After waiting at least 30 seconds, another valid inquiry was submitted.

Result:

- submission succeeded
- inquiry email arrived

This demonstrated that the cooldown blocks immediate repeat submissions while allowing normal submissions after expiration.

## Day 39 Result

Day 39 successfully added and deployed lightweight duplicate-submission protection for the production inquiry form.

Final verified state:

- 30-second frontend cooldown implemented
- cooldown is memory-only
- cooldown starts only after successful requests
- failed requests do not trigger cooldown
- immediate duplicate submissions are blocked
- submissions work after cooldown expiration
- API endpoint unchanged
- API payload unchanged
- 8 frontend tests passing
- website validation passing
- CI passing
- exact reviewed commit deployed
- live CloudFront asset matches repository
- CloudFront returns HTTP 200
- direct S3 remains HTTP 403
- controlled browser validation passed
- no Terraform infrastructure changes were required

## Security Boundary

The Day 39 frontend cooldown is a usability and accidental-duplicate control.

It must not be treated as complete abuse protection because a client-side memory-only control can be bypassed by refreshing the page, opening another browser context, or calling the API directly.

Future hardening can add server-side controls such as API throttling or request-rate protection independently of this frontend safeguard.
