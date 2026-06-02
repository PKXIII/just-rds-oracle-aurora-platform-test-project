data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Two AZs is the minimum for a DB subnet group and for Multi-AZ failover.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name_prefix}-vpc" }
}

# Private subnets hold the databases. No route to the internet by default.
resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)

  tags = {
    Name = "${var.name_prefix}-private-${local.azs[count.index]}"
    Tier = "private"
  }
}

# Public subnets exist only so NAT/egress can be added later if ever needed.
resource "aws_subnet" "public" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 8)

  tags = {
    Name = "${var.name_prefix}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_internet_gateway" "this" {
  count  = var.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway ? 1 : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
  tags       = { Name = "${var.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "${var.name_prefix}-nat" }
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-private-rt" }
}

resource "aws_route" "private_egress" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "${var.name_prefix}-db-subnets" }
}

# Database security group. Ingress is restricted to inside the VPC only — there is
# deliberately no 0.0.0.0/0 rule. App tiers connect from within the VPC / via peering.
resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "Allow database ports from within the VPC only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Oracle listener from within VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "MySQL/Aurora from within VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Outbound restricted to within the VPC (least privilege)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "${var.name_prefix}-db-sg" }
}

# AWS always creates a default security group per VPC. It should never carry
# workloads, so we lock it to deny all traffic in both directions. Satisfies PCI
# segmentation and checkov CKV2_AWS_12 — everything must use the explicit db SG.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
  # No ingress/egress blocks == deny all.
  tags = { Name = "${var.name_prefix}-default-deny-all" }
}

# ---------------------------------------------------------------------------
# VPC Endpoints
# Let VPC-resident compute (a Secrets Manager rotation Lambda, an app tier, or a
# bastion) reach AWS APIs *privately* — no route to the internet, no NAT Gateway.
# This is the cheaper, more PCI-friendly alternative to NAT for AWS-only egress.
#
# The S3 gateway endpoint is free and always on. Interface endpoints bill ~$0.01/hr
# each (~$7/mo), so they are gated behind a flag and off by default.
# Note: RDS/Aurora are managed services and do NOT traverse these endpoints.
# ---------------------------------------------------------------------------
data "aws_region" "current" {}

# S3 — gateway endpoint (free). Also enables RDS S3 integration / Data Pump export.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.name_prefix}-s3-endpoint" }
}

# Dedicated SG for interface endpoints: HTTPS from within the VPC only.
resource "aws_security_group" "endpoints" {
  count       = var.enable_interface_endpoints ? 1 : 0
  name        = "${var.name_prefix}-vpce-sg"
  description = "HTTPS to interface VPC endpoints from within the VPC"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from within VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Omitting egress == deny all outbound from the endpoint SG (least privilege).
  tags = { Name = "${var.name_prefix}-vpce-sg" }
}

locals {
  # The AWS APIs VPC-resident compute actually calls in this platform.
  interface_endpoints = var.enable_interface_endpoints ? toset([
    "secretsmanager", # fetch DB credentials / run rotation
    "monitoring",     # publish custom CloudWatch metrics
    "logs",           # ship application logs to CloudWatch Logs
  ]) : toset([])
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_endpoints
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true
  tags                = { Name = "${var.name_prefix}-${each.key}-endpoint" }
}
