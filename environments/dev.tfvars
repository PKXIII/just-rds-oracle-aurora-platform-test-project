# DEV — optimised for the lowest possible cost.
# Single-AZ, smallest viable instances, no NAT Gateway, no deletion protection so
# `terraform destroy` always works. This is the profile you run plan against for free.

environment        = "dev"
aws_region         = "ap-northeast-1"
enable_nat_gateway = false
monthly_budget_usd = 5

oracle = {
  engine              = "oracle-se2"
  engine_version      = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
  license_model       = "license-included"
  instance_class      = "db.t3.small"
  allocated_storage   = 20
  multi_az            = false # single-AZ in dev — halves the instance bill
  backup_retention    = 1     # minimum; we don't need PITR history in dev
  deletion_protection = false
}

aurora = {
  engine_version      = "8.0.mysql_aurora.3.05.2"
  instance_class      = "db.t3.medium"
  reader_count        = 0 # writer only — no reader to pay for in dev
  backup_retention    = 1
  deletion_protection = false
}

# Leave alarm_email / pagerduty_endpoint empty in dev to skip subscriptions.
alarm_email        = ""
pagerduty_endpoint = ""
