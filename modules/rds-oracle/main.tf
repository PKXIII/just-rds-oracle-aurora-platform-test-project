# Parameter group enabling Oracle native auditing. Audit trail to DB plus the
# audit/listener/alert logs shipped to CloudWatch give the tamper-evident trail
# PCI DSS Req. 10 asks for.
resource "aws_db_parameter_group" "oracle" {
  name        = "${var.name_prefix}-oracle-pg"
  family      = "oracle-se2-19"
  description = "Oracle SE2 19c parameters with auditing enabled"

  parameter {
    name         = "audit_trail"
    value        = "DB,EXTENDED"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "oracle" {
  identifier     = "${var.name_prefix}-oracle"
  engine         = var.engine
  engine_version = var.engine_version
  license_model  = var.license_model
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2 # storage autoscaling ceiling
  storage_type          = "gp3"

  # Credentials come from the Secrets Manager-backed values, not literals.
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.oracle.name
  multi_az               = var.multi_az
  publicly_accessible    = false

  # --- Security / PCI DSS ---
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_arn
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["alert", "audit", "listener", "trace"]

  # --- Backup / recovery ---
  backup_retention_period   = var.backup_retention
  backup_window             = "17:00-18:00" # UTC == 02:00-03:00 JST
  maintenance_window        = "sun:18:00-sun:19:00"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.name_prefix}-oracle-final" : null

  # --- Enhanced monitoring + Performance Insights ---
  monitoring_interval                   = 60
  monitoring_role_arn                   = var.monitoring_role_arn
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7

  auto_minor_version_upgrade = true
  apply_immediately          = var.deletion_protection ? false : true
}
