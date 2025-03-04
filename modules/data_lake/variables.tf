variable "environment" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "project_name" {
  description = "Project name to be used as a prefix for resources"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket for the data lake"
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain data before expiration"
  type        = number
  default     = 365
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_access_logs" {
  description = "Enable access logging for the S3 bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}