# Static Hosting Plan

## Goal

Host my portfolio using AWS services in a simple, secure, and professional architecture.

The planned architecture is:

S3 → CloudFront → Custom Domain / HTTPS

## What S3 Will Do

S3 will store the static website files for the portfolio.

These files may include:

- `index.html`
- CSS files
- JavaScript files
- Images
- Resume PDF
- Project screenshots

S3 is a good fit because the portfolio is mostly a static website. It does not need a backend server at the beginning.

## What CloudFront Will Do

CloudFront will deliver the portfolio files to users faster and more securely.

CloudFront helps by:

- Caching content at edge locations
- Reducing load on the S3 origin
- Improving performance for visitors
- Supporting HTTPS
- Creating a more production-like architecture

## Static Website Hosting

A static website is made of files that are served directly to users.

Examples:

- HTML
- CSS
- JavaScript
- Images
- PDFs

A static website does not require backend server-side code to generate pages.

## Why Not Only Use S3 Website Endpoint?

Using only an S3 website endpoint is simpler, but CloudFront is better for a portfolio because it supports a stronger production-style setup.

CloudFront adds:

- Better performance
- Edge caching
- HTTPS support
- Better custom domain setup
- A stronger architecture story for interviews

## Public Access Consideration

Public access means people on the internet can access bucket files.

This can be risky if private files are accidentally exposed.

For the final version, I should avoid making unnecessary files public and use controlled access wherever possible.

## S3 Standard vs S3 Glacier

S3 Standard should be used for active website files because those files need fast access.

S3 Glacier should not be used for active portfolio files because it is meant for cheaper archive storage with slower retrieval.

## Future Improvements

Later, this project can add:

- Custom domain
- HTTPS certificate
- CloudFront distribution
- Monitoring
- Deployment automation
- Architecture diagram
- Cost notes
- Security notes

## Interview Explanation

This portfolio will show that I understand basic cloud hosting architecture.

S3 stores the website files.

CloudFront delivers those files through edge locations for faster and more secure access.

This setup is simple, low-cost, scalable, and more professional than only uploading files to a basic website builder.

