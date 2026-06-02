variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "enable_nat_gateway" {
  description = "Create IGW + NAT Gateway for private egress. Off by default (cost)."
  type        = bool
  default     = false
}

variable "enable_interface_endpoints" {
  description = <<-EOT
    Create interface VPC endpoints (Secrets Manager, CloudWatch metrics, Logs) so
    VPC-resident compute reaches AWS APIs without a NAT Gateway. ~$7/mo each, so
    off by default. The free S3 gateway endpoint is always created regardless.
  EOT
  type        = bool
  default     = false
}
