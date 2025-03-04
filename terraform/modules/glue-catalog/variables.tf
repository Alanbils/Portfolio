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

variable "data_lake_bucket_arn" {
  description = "The ARN of the data lake S3 bucket"
  type        = string
}

variable "data_lake_bucket_name" {
  description = "The name of the data lake S3 bucket"
  type        = string
}

variable "crawler_schedule" {
  description = "Cron expression for crawler schedule (null means no schedule, trigger manually)"
  type        = string
  default     = null
}

variable "enable_table_versions" {
  description = "Whether to enable versioning of Glue tables"
  type        = bool
  default     = true
}

variable "athena_workgroup" {
  description = "Name of Athena workgroup to use with Glue catalog"
  type        = string
  default     = "primary"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}