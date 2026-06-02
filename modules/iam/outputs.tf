output "rds_monitoring_role_arn" {
  description = "IAM role ARN for RDS enhanced monitoring."
  value       = aws_iam_role.rds_monitoring.arn
}
