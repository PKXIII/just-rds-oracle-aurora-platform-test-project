output "oracle_secret_arn" {
  description = "ARN of the Oracle master secret."
  value       = aws_secretsmanager_secret.oracle.arn
}

output "oracle_username" {
  description = "Oracle master username."
  value       = var.oracle_username
}

output "oracle_password" {
  description = "Generated Oracle master password."
  value       = random_password.oracle.result
  sensitive   = true
}

output "aurora_secret_arn" {
  description = "ARN of the Aurora master secret."
  value       = aws_secretsmanager_secret.aurora.arn
}

output "aurora_username" {
  description = "Aurora master username."
  value       = var.aurora_username
}

output "aurora_password" {
  description = "Generated Aurora master password."
  value       = random_password.aurora.result
  sensitive   = true
}
