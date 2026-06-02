variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names."
}

variable "alarm_email" {
  type        = string
  default     = ""
  description = "Email subscribed to the alarm topic. Empty = skip."
}

variable "pagerduty_endpoint" {
  type        = string
  default     = ""
  sensitive   = true
  description = "PagerDuty/Slack HTTPS endpoint. Empty = skip."
}

variable "oracle_instance_id" {
  type        = string
  description = "Oracle DB instance identifier for alarm dimensions."
}

variable "aurora_cluster_id" {
  type        = string
  description = "Aurora cluster identifier for alarm dimensions."
}

variable "aurora_reader_count" {
  type        = number
  default     = 0
  description = "Reader count; gates the replica-lag alarm."
}
