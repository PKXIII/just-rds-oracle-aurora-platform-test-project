variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names."
}

variable "subnet_group_name" {
  type        = string
  description = "DB subnet group to launch into."
}

variable "security_group_id" {
  type        = string
  description = "Security group attached to the cluster."
}

variable "kms_key_arn" {
  type        = string
  description = "CMK ARN for storage and Performance Insights encryption."
}

variable "master_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret (for reference/tags)."
}

variable "master_username" {
  type        = string
  description = "Master username, sourced from the secrets module."
}

variable "master_password" {
  type        = string
  sensitive   = true
  description = "Master password, sourced from the secrets module."
}

variable "monitoring_role_arn" {
  type        = string
  description = "IAM role ARN for RDS enhanced monitoring."
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "reader_count" {
  type        = number
  default     = 0
  description = "Number of reader instances in addition to the writer."
}

variable "backup_retention" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = false
}
