# Frontend Inquiry Production Evidence — August 14, 2026

## Objective

Connect the live portfolio website to the production serverless inquiry backend completed on Day 36.

Final request path:

Browser
→ CloudFront
→ `website/app.js`
→ API Gateway
→ Lambda
→ SNS
→ confirmed email subscriber

## Frontend Implementation

Added a production inquiry form to the Connect section with:

- Name
- Email
- Message
- Send message button
- live status region

Client validation mirrors the backend contract:

- name: 2–100 characters
- email: 3–254 characters
- message: 10–2000 characters

The browser trims values before submission and prevents whitespace-only values from reaching the API.

The frontend sends exactly:

- `name`
- `email`
- `message`

No AWS credentials or secrets are stored in frontend code.

## Frontend Behavior

`website/app.js`:

- uses one production API endpoint
- sends HTTP POST
- sends JSON
- disables the submit button during requests
- shows a sending state
- resets the form after success
- shows a generic success message
- shows a generic error message for HTTP/network failures
- does not write inquiry data to console
- does not persist inquiry data in localStorage, sessionStorage, or cookies

## Automated Frontend Tests

Added:

`tests/test_frontend_inquiry.js`

Node built-ins only.

Tests:

1. Native invalid form blocks fetch.
2. Trimmed invalid values block fetch.
3. Successful submission trims payload and resets form.
4. HTTP failure returns generic UI error.
5. Network failure returns generic UI error.

Final result:

- 5 passed
- 0 failed

The website validation script now executes the frontend behavior test suite.

The production deployment workflow also runs the frontend behavior suite before AWS authentication.

## CI

Frontend integration commit:

`e6a1850 Integrate portfolio inquiry frontend`

Applicable GitHub Actions CI:

`Validate Portfolio Website`

Run:

`31858138808`

Result:

- completed
- success

Terraform and Python CI workflows did not run because their path filters did not match the frontend commit.

## Production Deployment

Production deployment remained manually controlled through:

`workflow_dispatch`

Deployment was run from:

- branch: main
- `run_failure_test=false`

Production deployment run:

`31859124917`

Deployment commit:

`e6a185039b7c616d688c1813b8305dac23cd7937`

Result:

- completed
- success

The deployment used the existing GitHub Actions + AWS OIDC deployment path.

No manual production `aws s3 sync` was used.

## Deployment Scope

Pre-deployment S3 sync dry run showed:

- upload `app.js`
- upload `index.html`
- upload `styles.css`
- no deletes

After deployment, production S3 contained:

- `app.js`
- `index.html`
- `styles.css`

## Independent Live Validation

Live CloudFront files were downloaded independently after the GitHub Actions deployment.

SHA256 comparison confirmed:

- live `index.html` exactly matched repository
- live `styles.css` exactly matched repository
- live `app.js` exactly matched repository

HTTP validation:

- CloudFront root: 200
- CloudFront index.html: 200
- CloudFront styles.css: 200
- CloudFront app.js: 200
- Direct S3 index.html: 403

The private S3 / CloudFront OAC security model remained intact.

## Live Form Verification

The live HTML contained:

- inquiry form
- name input
- email input
- message textarea
- submit button
- status element
- deferred `app.js` script reference

The live JavaScript contained:

- one production API endpoint
- POST request
- JSON content type
- JSON payload
- loading-state button disable
- form reset after success

No frontend inquiry logging or browser persistence behavior was detected.

## CORS

Production preflight returned HTTP 204.

Allowed origin:

`https://d1wnw5kep14m5j.cloudfront.net`

Allowed method:

`POST`

Allowed header:

`content-type`

## Backend Regression

After frontend deployment:

- Terraform production plan returned No changes.
- Terraform detailed exit code: 0.
- Production inquiry API remained reachable and validating.
- Existing backend infrastructure remained converged.

## Real Browser End-to-End Test

A controlled inquiry was submitted through the actual deployed website form.

Results:

- browser success state appeared
- form cleared after submission
- production API accepted the request
- SNS notification email arrived successfully

This proves the complete production visitor path:

Browser
→ CloudFront
→ JavaScript
→ API Gateway
→ Lambda
→ SNS
→ email notification

## Cache Observation

Immediately after deployment, one browser view initially displayed the older Connect section.

Using a cache-busting query string exposed the new Day 37 page.

Follow-up inspection showed:

- normal root now serves the Day 37 form
- cache-busted root serves the Day 37 form
- both responses have identical SHA256
- CloudFront currently serves cached objects
- S3 objects have no explicit Cache-Control metadata

No Day 37 cache configuration change was made because the normal production URL converged to the deployed content and independent file verification was clean.

## Final Status

Day 37 frontend integration is complete.

Verified:

- production contact form
- client validation
- trimmed-value validation
- loading state
- success state
- error state
- privacy-safe frontend behavior
- automated behavior tests
- CI
- controlled GitHub Actions deployment
- OIDC deployment path
- live asset equality
- S3 privacy
- CORS
- Terraform zero drift
- real browser submission
- real SNS email delivery
