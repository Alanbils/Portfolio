# Security Groups Module - Variables

variable "vpc_id" {
description = "The ID of the VPC where security groups will be created"
type        = string
}

variable "environment" {
description = "The environment name (dev, staging, prod)"
type        = string
}

variable "project" {
description = "The name of the project"
type        = string
default     = "aws-portfolio"
}

variable "tags" {
description = "A map of tags to add to all resources"
type        = map(string)
default     = {}
}

# Database security group variables
variable "db_port_mysql" {
description = "The port for MySQL database connections"
type        = number
default     = 3306
}

variable "db_port_postgres" {
description = "The port for PostgreSQL database connections"
type        = number
default     = 5432
}

variable "db_ingress_cidr_blocks" {
description = "CIDR blocks allowed to connect to database instances"
type        = list(string)
default     = []
}

# Redshift security group variables
variable "redshift_port" {
description = "The port for Redshift cluster connections"
type        = number
default     = 5439
}

variable "redshift_ingress_cidr_blocks" {
description = "CIDR blocks allowed to connect to Redshift clusters"
type        = list(string)
default     = []
}

# Lambda security group variables
variable "lambda_egress_cidr_blocks" {
description = "CIDR blocks that Lambda functions can connect to"
type        = list(string)
default     = ["0.0.0.0/0"]
}

# Glue security group variables
variable "glue_service_port" {
description = "The port for AWS Glue service connections"
type        = number
default     = 443
}

# DMS security group variables
variable "dms_port" {
description = "The port for AWS DMS replication instances"
type        = number
default     = 443
}

# Monitoring security group variables
variable "monitoring_ingress_cidr_blocks" {
description = "CIDR blocks allowed to connect to monitoring services"
type        = list(string)
default     = []
}

variable "monitoring_ports" {
description = "Ports to open for monitoring services"
type        = list(number)
default     = [443, 80, 8080, 9090]
}

# Application security group variables
variable "app_ports" {
description = "Ports to open for application services"
type        = list(number)
default     = [80, 443, 8080]
}

variable "app_ingress_cidr_blocks" {
description = "CIDR blocks allowed to connect to application services"
type        = list(string)
default     = ["0.0.0.0/0"]
}

# Internal services security group variables
variable "internal_service_ports" {
description = "Ports to open for internal services"
type        = list(number)
default     = [443, 80, 8080]
}

variable "internal_service_cidr_blocks" {
description = "CIDR blocks for internal services communication"
type        = list(string)
default     = []
}
