resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${var.name_prefix}-aurora-cpg"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 cluster params with audit logging"

  # General log + slow query log feed the dba-ops-toolkit slow-query reporter.
  parameter {
    name  = "server_audit_logging"
    value = "1"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.name_prefix}-aurora"
  engine             = "aurora-mysql"
  engine_version     = var.engine_version
  engine_mode        = "provisioned"

  master_username = var.master_username
  master_password = var.master_password

  db_subnet_group_name            = var.subnet_group_name
  vpc_security_group_ids          = [var.security_group_id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  # --- Security / PCI DSS ---
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_arn
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["audit", "error", "slowquery"]

  # --- Backup / recovery ---
  backup_retention_period   = var.backup_retention
  preferred_backup_window   = "17:00-18:00"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.name_prefix}-aurora-final" : null

  apply_immediately = var.deletion_protection ? false : true
}

# One writer (index 0) plus var.reader_count readers. In dev reader_count = 0, so a
# single instance keeps cost down; prod adds a reader in the second AZ for failover.
resource "aws_rds_cluster_instance" "aurora" {
  count              = 1 + var.reader_count
  identifier         = "${var.name_prefix}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
  instance_class     = var.instance_class

  db_subnet_group_name = var.subnet_group_name
  publicly_accessible  = false

  monitoring_interval                   = 60
  monitoring_role_arn                   = var.monitoring_role_arn
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7

  auto_minor_version_upgrade = true
}
