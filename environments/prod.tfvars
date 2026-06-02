# PROD — the mission-critical profile for a credit-card platform.
# Multi-AZ Oracle for automatic failover, an Aurora reader in a second AZ, longer
# backup retention, and deletion protection so a database can't be destroyed by a
# stray `terraform destroy`.
#
# NOTE: applying this profile incurs real, ongoing cost. It exists to show the
# production-grade intent; it is not meant to be left running for a showcase.

environment                = "prod"
aws_region                 = "ap-northeast-1"
enable_nat_gateway         = false
enable_interface_endpoints = true # private AWS API access (Secrets Manager rotation, CloudWatch) without NAT
monthly_budget_usd         = 1500

oracle = {
  engine              = "oracle-se2"
  engine_version      = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
  license_model       = "license-included"
  instance_class      = "db.r6i.large"
  allocated_storage   = 200
  multi_az            = true # automatic standby failover
  backup_retention    = 35   # max PITR window
  deletion_protection = true
}

aurora = {
  engine_version      = "8.0.mysql_aurora.3.05.2"
  instance_class      = "db.r6g.large"
  reader_count        = 1 # reader in a second AZ for read scaling + failover
  backup_retention    = 35
  deletion_protection = true
}

# Wire these to the real on-call channels before applying prod.
alarm_email        = "dba-oncall@example.com"
pagerduty_endpoint = ""
