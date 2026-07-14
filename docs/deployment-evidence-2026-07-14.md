# Portfolio Deployment Evidence — July 14, 2026

## Deployment Type

Manual static website update.

## Source Repository

`2aron41/aws-serverless-portfolio`

## Files Updated

- `website/index.html`

## Website Changes

- Changed the project status from `In development` to `Live on AWS`.
- Added the deployed architecture description.
- Added a link to the GitHub project repository.

## Deployment Process

1. Updated `website/index.html` in GitHub Codespaces.
2. Previewed the website locally.
3. Reviewed the Git changes.
4. Committed and pushed the changes to GitHub.
5. Downloaded the updated `index.html`.
6. Uploaded it to the private S3 bucket.
7. Replaced the previous `index.html` object.
8. Created CloudFront cache invalidations.
9. Waited for the invalidations to reach `Completed`.
10. Tested the exact CloudFront distribution domain in a private browser window.

## Validation Results

- CloudFront website loaded successfully.
- HTTPS worked.
- CSS styling loaded successfully.
- Updated project status appeared.
- Architecture description appeared.
- GitHub project link worked.
- Direct S3 access remained blocked.
- S3 Block Public Access remained enabled.

## Problems Encountered

- The updated file was initially uploaded as `index-.html` rather than `index.html`.
- The website continued displaying the old version after invalidation.
- Multiple invalidations were created while troubleshooting.
- An old or incorrect website URL was opened during testing.

## Resolution

- Deleted the incorrectly named `index-.html` object.
- Uploaded the updated file using the exact name `index.html`.
- Confirmed that S3 contained the updated 2.4 KB object.
- Invalidated all CloudFront paths using `/*`.
- Copied the exact distribution domain directly from the CloudFront console.
- Opened the correct domain in a new private browser window.
- Confirmed the updated website appeared successfully.

## Architecture

```text
GitHub repository
       |
       | Manual download and upload
       v
Private Amazon S3 bucket
       |
       | Origin Access Control
       v
Amazon CloudFront
       |
       | HTTPS
       v
Website visitor
