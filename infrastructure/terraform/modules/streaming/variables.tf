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

variable "shard_count" {
  description = "Number of shards for the Kinesis stream"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Data retention period in hours"
  type        = number
  default     = 24
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "output_bucket" {
  description = "S3 bucket for storing processed data"
  type        = string
}

variable "output_bucket_arn" {
  description = "ARN of the S3 bucket for storing processed data"
  type        = string
}
