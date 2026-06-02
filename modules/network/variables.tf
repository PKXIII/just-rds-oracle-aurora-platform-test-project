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
