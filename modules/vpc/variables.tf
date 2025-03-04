variable "name" {
description = "Name prefix for all resources in the VPC module"
type        = string
}

variable "vpc_cidr" {
description = "CIDR block for the VPC"
type        = string
default     = "10.0.0.0/16"
}

variable "region" {
description = "AWS region where resources will be created"
type        = string
default     = "us-east-1"
}

variable "availability_zones" {
description = "List of availability zones to use for resources"
type        = list(string)
default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
description = "CIDR blocks for public subnets"
type        = list(string)
default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
description = "CIDR blocks for private subnets"
type        = list(string)
default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
description = "Set to true to create a single NAT Gateway for all private subnets"
type        = bool
default     = false
}

variable "enable_s3_endpoint" {
description = "Set to true to enable S3 VPC endpoint"
type        = bool
default     = true
}

variable "enable_dynamodb_endpoint" {
description = "Set to true to enable DynamoDB VPC endpoint"
type        = bool
default     = true
}

variable "enable_vpc_endpoints" {
description = "Set to true to enable interface VPC endpoints for AWS services"
type        = bool
default     = true
}

variable "interface_vpc_endpoints" {
description = "List of AWS service interfaces to create VPC endpoints for (e.g., ssm, ec2, etc.)"
type        = list(string)
default     = ["ssm", "ssmmessages", "ec2", "ec2messages", "kms", "logs", "monitoring", "secretsmanager"]
}

variable "enable_flow_logs" {
description = "Set to true to enable VPC Flow Logs for network traffic monitoring"
type        = bool
default     = true
}

variable "flow_logs_destination_arn" {
description = "ARN of the S3 bucket to store VPC Flow Logs"
type        = string
default     = ""
}

variable "tags" {
description = "Tags to apply to all resources"
type        = map(string)
default     = {}
}

