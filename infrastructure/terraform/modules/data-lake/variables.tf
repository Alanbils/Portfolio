variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "bucket_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for S3 bucket"
  type = list(object({
    id        = string
    enabled   = bool
    prefix    = string
    transitions = list(object({
      days          = number
      storage_class = string
    }))
  }))
  default = []
}

variable "enable_encryption" {
  description = "Enable KMS encryption for S3 bucket"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ID for S3 bucket encryption"
  type        = string
  default     = null
}
