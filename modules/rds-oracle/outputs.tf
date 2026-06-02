output "instance_id" {
  description = "RDS instance identifier (used by CloudWatch alarms)."
  value       = aws_db_instance.oracle.id
}

output "endpoint" {
  description = "Oracle connection endpoint."
  value       = aws_db_instance.oracle.endpoint
}

output "arn" {
  description = "ARN of the Oracle instance."
  value       = aws_db_instance.oracle.arn
}
