# Common Terraform variables used across all environments

# Organization and project information
project_name = "aws-portfolio"
organization = "demo-org"

# Networking
vpc_cidr = "10.0.0.0/16"

# Default settings for EC2 instances
default_ami_owners = ["amazon"]
ssh_key_name       = "portfolio-key"

# IAM settings
iam_path           = "/portfolio/"

# Security settings
security_group_default_egress = [{
from_port   = 0
to_port     = 0
protocol    = "-1"
cidr_blocks = ["0.0.0.0/0"]
description = "Allow all outbound traffic"
}]

# RDS settings
rds_engine_version = "13.4"
rds_family         = "postgres13"

# Redshift settings
redshift_port      = 5439

# Lambda settings
lambda_runtime     = "python3.9"
lambda_timeout     = 30

# DynamoDB settings
dynamodb_billing_mode = "PAY_PER_REQUEST"

# S3 settings
s3_versioning      = true
s3_lifecycle_rules = [{
id      = "transition-to-ia"
enabled = true
transition = [{
    days          = 30
    storage_class = "STANDARD_IA"
}]
}]

# Glue and DMS settings
glue_python_version = "3"
dms_engine_version  = "3.4.6"

# Common tags applied to all resources
default_tags = {
Terraform   = "true"
Portfolio   = "true"
Creator     = "Terragrunt"
}

