variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "database_name" {
  description = "Name of the Glue catalog database"
  type        = string
  default     = "data_catalog"
}

variable "crawler_name" {
  description = "Name of the Glue crawler"
  type        = string
  default     = "data-lake-crawler"
}

variable "crawler_schedule" {
  description = "Cron schedule for the crawler"
  type        = string
  default     = "cron(0 0 * * ? *)"  # Run daily at midnight
}

variable "table_prefix" {
  description = "Prefix to add to tables created by the crawler"
  type        = string
  default     = "raw_"
}

variable "data_lake_bucket" {
  description = "S3 bucket name for the data lake"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}