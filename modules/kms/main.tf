# Customer-managed key used to encrypt RDS storage, Aurora storage, and the
# Secrets Manager secrets. A CMK (not the AWS-managed default) is required so key
# rotation and access can be audited — a PCI DSS expectation.
resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} database encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-db"
  target_key_id = aws_kms_key.this.key_id
}
