provider "aws" {
  region = var.aws_region

  # Every resource in this account/workspace is tagged so cost can be traced per
  # environment in Cost Explorer and orphaned resources are easy to find.
  default_tags {
    tags = {
      Project     = "rds-oracle-aurora-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
      CostCenter  = "dba-platform"
    }
  }
}
