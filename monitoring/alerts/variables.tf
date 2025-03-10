variable "alert_email" {
  description = "Email address to receive data quality alerts"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "project_prefix" {
  description = "Prefix to be used for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
