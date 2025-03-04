variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The AWS region where resources will be created"
  type        = string
}

variable "data_lake_bucket_arn" {
  description = "The ARN of the data lake S3 bucket"
  type        = string
}

variable "data_streams" {
  description = "Map of data stream configurations (stream_name => config)"
  type = map(object({
    shard_count      = number
    retention_period = number
    on_demand_mode   = bool
  }))
  
  default = {
    clickstream = {
      shard_count      = 2
      retention_period = 24
      on_demand_mode   = false
    },
    transactions = {
      shard_count      = 4
      retention_period = 48
      on_demand_mode   = false
    },
    logs = {
      shard_count      = 1
      retention_period = 24
      on_demand_mode   = true
    }
  }
}

variable "firehose_buffer_size" {
  description = "Buffer size in MB for Firehose delivery stream (1-128)"
  type        = number
  default     = 5
}

variable "firehose_buffer_interval" {
  description = "Buffer interval in seconds for Firehose delivery stream (60-900)"
  type        = number
  default     = 300
}

variable "enable_data_format_conversion" {
  description = "Enable data format conversion (JSON to Parquet) in Firehose"
  type        = bool
  default     = false
}

variable "glue_database_name" {
  description = "Glue database name for schema reference (required if enable_data_format_conversion=true)"
  type        = string
  default     = null
}

variable "enable_processing" {
  description = "Enable Lambda processing in Firehose"
  type        = bool
  default     = false
}

variable "processing_lambda_arn" {
  description = "ARN of Lambda function for processing (required if enable_processing=true)"
  type        = string
  default     = null
}

variable "use_cmk" {
  description = "Use customer managed key for Kinesis encryption"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for Kinesis encryption (required if use_cmk=true)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to keep CloudWatch logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}