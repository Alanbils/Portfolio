variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The AWS region where resources will be created"
  type        = string
}

variable "is_production" {
  description = "Boolean flag to indicate if this is a production environment"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of KMS key to use for bucket encryption (if not provided, AES256 is used)"
  type        = string
  default     = null
}

variable "enable_intelligent_tiering" {
  description = "Enable intelligent tiering for cost optimization"
  type        = bool
  default     = true
}

variable "access_log_bucket" {
  description = "Bucket name for access logging (if not provided, logging is disabled)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}