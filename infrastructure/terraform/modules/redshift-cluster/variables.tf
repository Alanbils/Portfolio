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

variable "vpc_id" {
  description = "The VPC ID where the Redshift cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the Redshift subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to Redshift (default is unrestricted in non-prod)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "publicly_accessible" {
  description = "Indicates whether the cluster is publicly accessible"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "The name of the first database to be created when the cluster is created"
  type        = string
  default     = "analytics"
}

variable "master_username" {
  description = "The username for the master database user"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "The password for the master database user"
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "The type of nodes in the cluster"
  type        = string
  default     = "dc2.large"
}

variable "node_count" {
  description = "The number of nodes in the cluster (minimum 2 for multi-node)"
  type        = number
  default     = 2
}

variable "availability_zone" {
  description = "The AZ where the Redshift cluster will be created (single-AZ deployment)"
  type        = string
  default     = null
}

variable "snapshot_copy_region" {
  description = "Region to copy snapshots to for disaster recovery"
  type        = string
}

variable "snapshot_retention_days" {
  description = "Number of days to retain automated snapshots"
  type        = number
  default     = 7
}

variable "use_cmk" {
  description = "Use customer managed key for Redshift encryption"
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "S3 bucket name for Redshift logs"
  type        = string
}

variable "data_lake_bucket_arn" {
  description = "ARN of the data lake S3 bucket for COPY/UNLOAD operations"
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs to notify when Redshift alarms trigger"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}