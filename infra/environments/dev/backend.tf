terraform {
  backend "s3" {
    bucket       = "cloud-ai-roadmap-terraform-state-510497448584-us-east-1"
    key          = "aws-serverless-portfolio/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
