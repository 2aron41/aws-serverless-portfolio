locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Purpose     = "Portfolio inquiry service"
  }
}

resource "aws_sns_topic" "inquiry" {
  count = var.enable_inquiry ? 1 : 0

  name = "${var.project_name}-${var.environment}-inquiries"

  tags = local.common_tags
}
