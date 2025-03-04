variable "environment" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "project_name" {
  description = "Project name to be used as a prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the Redshift cluster will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the Redshift cluster will be deployed"
  type        = list(string)
}

variable "database_name" {
  description = "Name of the first database to be created when the cluster is created"
  type        = string
  default     = "analytics"
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "master_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "The node type to be provisioned for the Redshift cluster"
  type        = string
}

variable "cluster_type" {
  description = "The type of the cluster, valid values are single-node and multi-node"
  type        = string
  default     = "multi-node"
  
  validation {
    condition     = contains(["single-node", "multi-node"], var.cluster_type)
    error_message = "The cluster_type must be either single-node or multi-node."
  }
}

variable "number_of_nodes" {
  description = "The number of compute nodes in the cluster. Required when cluster_type is multi-node"
  type        = number
  default     = 2
}

variable "data_lake_bucket_arn" {
  description = "ARN of the data lake S3 bucket"
  type        = string
}

variable "logging_bucket" {
  description = "Name of the S3 bucket for cluster logging"
  type        = string
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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}