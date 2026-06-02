terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state is intentionally left as local backend for this showcase so the
  # repo runs with zero cloud cost. For a real deployment, uncomment and point at
  # an encrypted, versioned S3 bucket with a DynamoDB lock table.
  #
  # backend "s3" {
  #   bucket         = "paypay-card-tfstate"
  #   key            = "rds-oracle-aurora-platform/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   dynamodb_table = "tf-locks"
  #   encrypt        = true
  # }
}
