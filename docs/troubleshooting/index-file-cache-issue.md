# Troubleshooting: CloudFront Served Old Homepage

## Symptom

CloudFront continued showing the old homepage after I uploaded updated website files and created a cache invalidation.

## Expected Result

The CloudFront website should have displayed the updated homepage after the corrected file was uploaded and the invalidation completed.

## Actual Result

The website continued displaying the previous homepage because the updated file did not replace the existing `index.html` object.

## Evidence Checked

- S3 object name: The active homepage was `index.html`, but the updated file was initially uploaded as `index-.html`.
- S3 object size: The corrected `index.html` object was checked to confirm that its size matched the updated file.
- S3 object modified time: The object timestamp was checked to confirm that the corrected homepage had been uploaded.
- CloudFront default root object: `index.html`
- CloudFront distribution domain: `d1wnw5kep14m5j.cloudfront.net`
- Invalidation paths used: `/*`

## Root Cause

The updated homepage was uploaded as `index-.html` instead of `index.html`. Because CloudFront's default root object was still `index.html`, CloudFront continued retrieving and serving the older object.

## Fix

Deleted the incorrectly named `index-.html` object, uploaded the corrected file as `index.html`, and invalidated the relevant CloudFront paths.

## Verification

- CloudFront URL loaded the updated homepage.
- CSS loaded correctly.
- Direct S3 access remained blocked.
- S3 Block Public Access remained enabled.
- The CloudFront distribution continued using the private S3 bucket through Origin Access Control.

## Prevention

- Verify file names before upload.
- Confirm that the deployed object name exactly matches the CloudFront default root object.
- Compare object size and modified time after deployment.
- Use GitHub as the source of truth.
- Automate future deployments with S3 sync and CloudFront invalidation.
- Add file validation before allowing an automated deployment to continue.
