# Decision Log

## Decision 1: Use AWS as the primary cloud platform

### Decision
Focus on AWS before learning multiple cloud providers.

### Reason
AWS supports the certification path and projects I am currently completing. It also gives me a clear path to build portfolio projects that show cloud infrastructure, networking, monitoring, and security fundamentals.

### Alternatives
- Microsoft Azure
- Google Cloud Platform

### Trade-off
I gain depth in one platform first, but temporarily have less multi-cloud exposure.

---

## Decision 2: Use serverless services for the portfolio

### Decision
Use serverless AWS services where possible for the portfolio project.

### Reason
Serverless services reduce the need to manage servers directly. This makes the project simpler to deploy, cheaper to run, and easier to scale for a beginner cloud portfolio.

### Alternatives
- Host the portfolio on an EC2 instance
- Use a traditional web server
- Use a non-AWS hosting platform

### Trade-off
Serverless is simpler and cost-effective, but I get less direct practice managing operating systems and servers compared to EC2.

---

## Decision 3: Use CloudFront instead of only an S3 website endpoint

### Decision
Use CloudFront in front of the S3-hosted portfolio instead of relying only on the S3 static website endpoint.

### Reason
CloudFront improves performance by caching content closer to users through edge locations. It also supports HTTPS, custom domains, and a more production-like architecture.

### Alternatives
- Use only the S3 static website endpoint
- Host the site on EC2
- Use a third-party hosting platform

### Trade-off
CloudFront adds more setup and complexity, but it creates a better architecture and stronger portfolio story.
