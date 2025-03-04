variable "environment" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "project_name" {
  description = "Project name to be used as a prefix for resources"
  type        = string
}

variable "stream_name" {
  description = "Name for the Kinesis Data Stream"
  type        = string
}

variable "shard_count" {
  description = "Number of shards for the Kinesis Data Stream"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Length of time data records are accessible after they are added to the stream (hours)"
  type        = number
  default     = 24
}

variable "on_demand_mode" {
  description = "Whether to use on-demand mode for the Kinesis Data Stream"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm transitions (usually SNS topics)"
  type        = list(string)
  default     = []
}

variable "enable_firehose_delivery" {
  description = "Enable Kinesis Firehose delivery to S3"
  type        = bool
  default     = false
}

variable "data_lake_bucket_arn" {
  description = "ARN of the S3 bucket for data lake storage (for Firehose delivery)"
  type        = string
  default     = ""
}

variable "firehose_processor_lambda_arn" {
  description = "ARN of the Lambda function for Firehose data transformation"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}