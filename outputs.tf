output "oracle_endpoint" {
  description = "RDS for Oracle connection endpoint."
  value       = module.oracle.endpoint
}

output "oracle_secret_arn" {
  description = "Secrets Manager ARN holding the Oracle master credentials."
  value       = module.secrets.oracle_secret_arn
}

output "aurora_writer_endpoint" {
  description = "Aurora MySQL writer (cluster) endpoint."
  value       = module.aurora.writer_endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora MySQL reader endpoint (load-balanced across readers, prod only)."
  value       = module.aurora.reader_endpoint
}

output "aurora_secret_arn" {
  description = "Secrets Manager ARN holding the Aurora master credentials."
  value       = module.secrets.aurora_secret_arn
}

output "alarm_topic_arn" {
  description = "SNS topic that CloudWatch alarms publish to."
  value       = module.monitoring.alarm_topic_arn
}
