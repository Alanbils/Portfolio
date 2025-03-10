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

variable "shard_count" {
  description = "Number of shards for Kinesis stream"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Data retention period in hours for Kinesis stream"
  type        = number
  default     = 24
}

variable "output_bucket_arn" {
  description = "ARN of the S3 bucket for Firehose output"
  type        = string
}

variable "buffer_size_in_mbs" {
  description = "Buffer size in MBs for Firehose delivery to S3"
  type        = number
  default     = 128
}

variable "buffer_interval_in_seconds" {
  description = "Buffer interval in seconds for Firehose delivery to S3"
  type        = number
  default     = 60
}
