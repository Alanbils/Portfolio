variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_prefix" {
  description = "Prefix to be used for resource names"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "data_lake_bucket_name" {
  description = "Name of the data lake bucket"
  type        = string
}

variable "data_lake_bucket_acl" {
  description = "ACL to be applied to the data lake bucket"
  type        = string
  default     = "private"
}

variable "data_lake_key_prefix" {
  description = "Prefix to be used for data lake keys"
  type        = string
  default     = ""
}

variable "bucket_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for data lake buckets"
  type = list(object({
    id      = string
    enabled = bool
    prefix  = string
    transitions = list(object({
      days          = number
      storage_class = string
    }))
  }))
  default = []
}

variable "enable_encryption" {
  description = "Enable server-side encryption for S3 bucket"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}
