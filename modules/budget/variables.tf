variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names."
}

variable "monthly_budget_usd" {
  type        = number
  description = "Monthly cost ceiling in USD."
}

variable "notify_email" {
  type        = string
  default     = ""
  description = "Email for budget notifications. Empty = create budget without alerts."
}
