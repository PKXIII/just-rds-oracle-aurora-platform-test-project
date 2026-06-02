output "cluster_id" {
  description = "Aurora cluster identifier (used by CloudWatch alarms)."
  value       = aws_rds_cluster.aurora.id
}

output "writer_endpoint" {
  description = "Writer (cluster) endpoint."
  value       = aws_rds_cluster.aurora.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint (load-balanced across readers)."
  value       = aws_rds_cluster.aurora.reader_endpoint
}
