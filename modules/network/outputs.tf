output "vpc_id" {
  description = "ID of the platform VPC."
  value       = aws_vpc.this.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group spanning the private subnets."
  value       = aws_db_subnet_group.this.name
}

output "db_security_group_id" {
  description = "Security group ID for the database tier."
  value       = aws_security_group.db.id
}

output "s3_endpoint_id" {
  description = "ID of the S3 gateway VPC endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "interface_endpoint_ids" {
  description = "Map of service name to interface VPC endpoint ID (empty unless enabled)."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}
