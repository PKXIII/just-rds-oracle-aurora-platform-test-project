variable "aws_region" {
  description = "AWS region. PayPay Card runs in Tokyo, so default to ap-northeast-1."
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Deployment environment. Drives single-AZ vs Multi-AZ and instance sizing."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "owner" {
  description = "Tag value used to attribute cost and ownership."
  type        = string
  default     = "dba-platform-team"
}

variable "vpc_cidr" {
  description = "CIDR block for the platform VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "enable_nat_gateway" {
  description = <<-EOT
    NAT Gateway costs ~$33/month just to sit idle, so it is OFF by default.
    Databases live in private subnets with no outbound internet need. Only turn
    this on if a subnet genuinely needs egress (e.g. Lambda calling an external API).
    For AWS-only egress, prefer enable_interface_endpoints instead — cheaper and
    traffic never leaves the AWS network.
  EOT
  type        = bool
  default     = false
}

variable "enable_interface_endpoints" {
  description = <<-EOT
    Create interface VPC endpoints (Secrets Manager, CloudWatch, Logs) so
    VPC-resident compute reaches AWS APIs privately without a NAT Gateway.
    ~$7/month each, off by default. The free S3 gateway endpoint is always created.
  EOT
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# RDS for Oracle
# ---------------------------------------------------------------------------
variable "oracle" {
  description = "RDS for Oracle configuration. Sized small for dev; Multi-AZ only in prod."
  type = object({
    engine              = string
    engine_version      = string
    license_model       = string
    instance_class      = string
    allocated_storage   = number
    multi_az            = bool
    backup_retention    = number
    deletion_protection = bool
  })
  default = {
    engine              = "oracle-se2"
    engine_version      = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
    license_model       = "license-included"
    instance_class      = "db.t3.small"
    allocated_storage   = 20
    multi_az            = false
    backup_retention    = 7
    deletion_protection = false
  }
}

# ---------------------------------------------------------------------------
# Aurora MySQL
# ---------------------------------------------------------------------------
variable "aurora" {
  description = "Aurora MySQL cluster configuration. Reader instance added only in prod."
  type = object({
    engine_version      = string
    instance_class      = string
    reader_count        = number
    backup_retention    = number
    deletion_protection = bool
  })
  default = {
    engine_version      = "8.0.mysql_aurora.3.05.2"
    instance_class      = "db.t3.medium"
    reader_count        = 0
    backup_retention    = 7
    deletion_protection = false
  }
}

# ---------------------------------------------------------------------------
# Monitoring / alerting
# ---------------------------------------------------------------------------
variable "alarm_email" {
  description = "Email subscribed to the SNS alarm topic. Empty = no email subscription."
  type        = string
  default     = ""
}

variable "pagerduty_endpoint" {
  description = "PagerDuty (or Slack) HTTPS endpoint for the SNS topic. Empty = skip."
  type        = string
  default     = ""
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Cost guardrail
# ---------------------------------------------------------------------------
variable "monthly_budget_usd" {
  description = "Hard ceiling for AWS Budgets alerting. Notifies at 80% and 100%."
  type        = number
  default     = 5
}
