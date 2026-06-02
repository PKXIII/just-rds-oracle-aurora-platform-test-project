variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
}

variable "kms_key_arn" {
  description = "CMK ARN used to encrypt the secrets."
  type        = string
}

variable "oracle_username" {
  description = "Oracle master username."
  type        = string
  default     = "admin"
}

variable "aurora_username" {
  description = "Aurora master username."
  type        = string
  default     = "admin"
}
