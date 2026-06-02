locals {
  name_prefix = "ppc-${var.environment}"
}

# Foundational network: VPC, private DB subnets across two AZs, DB subnet group.
module "network" {
  source = "./modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
}

# Customer-managed KMS key for encryption at rest (PCI DSS Req. 3).
module "kms" {
  source = "./modules/kms"

  name_prefix = local.name_prefix
}

# Database credentials live in Secrets Manager — never in code or tfvars.
module "secrets" {
  source = "./modules/secrets"

  name_prefix = local.name_prefix
  kms_key_arn = module.kms.key_arn
}

# Enhanced-monitoring IAM role, split out so the DB modules and the alarm module
# don't form a dependency cycle.
module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
}

# RDS for Oracle (SE2, License Included).
module "oracle" {
  source = "./modules/rds-oracle"

  name_prefix         = local.name_prefix
  subnet_group_name   = module.network.db_subnet_group_name
  security_group_id   = module.network.db_security_group_id
  kms_key_arn         = module.kms.key_arn
  master_secret_arn   = module.secrets.oracle_secret_arn
  master_username     = module.secrets.oracle_username
  master_password     = module.secrets.oracle_password
  monitoring_role_arn = module.iam.rds_monitoring_role_arn

  engine              = var.oracle.engine
  engine_version      = var.oracle.engine_version
  license_model       = var.oracle.license_model
  instance_class      = var.oracle.instance_class
  allocated_storage   = var.oracle.allocated_storage
  multi_az            = var.oracle.multi_az
  backup_retention    = var.oracle.backup_retention
  deletion_protection = var.oracle.deletion_protection
}

# Aurora MySQL cluster (writer + optional reader).
module "aurora" {
  source = "./modules/aurora-mysql"

  name_prefix         = local.name_prefix
  subnet_group_name   = module.network.db_subnet_group_name
  security_group_id   = module.network.db_security_group_id
  kms_key_arn         = module.kms.key_arn
  master_secret_arn   = module.secrets.aurora_secret_arn
  master_username     = module.secrets.aurora_username
  master_password     = module.secrets.aurora_password
  monitoring_role_arn = module.iam.rds_monitoring_role_arn

  engine_version      = var.aurora.engine_version
  instance_class      = var.aurora.instance_class
  reader_count        = var.aurora.reader_count
  backup_retention    = var.aurora.backup_retention
  deletion_protection = var.aurora.deletion_protection
}

# CloudWatch alarms + SNS fan-out to email / PagerDuty. Depends on the database
# instance IDs, which is why the monitoring IAM role lives in its own module.
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix        = local.name_prefix
  alarm_email        = var.alarm_email
  pagerduty_endpoint = var.pagerduty_endpoint

  oracle_instance_id  = module.oracle.instance_id
  aurora_cluster_id   = module.aurora.cluster_id
  aurora_reader_count = var.aurora.reader_count
}

# AWS Budgets guardrail — the cost circuit breaker.
module "budget" {
  source = "./modules/budget"

  name_prefix        = local.name_prefix
  monthly_budget_usd = var.monthly_budget_usd
  notify_email       = var.alarm_email
}
