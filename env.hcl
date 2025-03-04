# This file defines environment-specific settings

locals {
# Environment-specific configuration values
env_vars = {
    dev = {
    instance_type         = "t3.small"
    rds_instance_class    = "db.t3.small"
    redshift_node_type    = "dc2.large"
    lambda_memory_size    = 128
    enable_detailed_monitoring = false
    multi_az              = false
    backup_retention      = 7
    deletion_protection   = false
    }
    
    staging = {
    instance_type         = "t3.medium"
    rds_instance_class    = "db.t3.medium"
    redshift_node_type    = "dc2.large"
    lambda_memory_size    = 256
    enable_detailed_monitoring = true
    multi_az              = true
    backup_retention      = 14
    deletion_protection   = true
    }
    
    prod = {
    instance_type         = "m5.large"
    rds_instance_class    = "db.m5.large"
    redshift_node_type    = "dc2.8xlarge"
    lambda_memory_size    = 512
    enable_detailed_monitoring = true
    multi_az              = true
    backup_retention      = 30
    deletion_protection   = true
    }
}

# Extract environment name from the file path
path_components = split("/", path_relative_to_include())
environment     = path_components[0]

# Get configuration for the current environment
env_config      = local.env_vars[local.environment]

# Define environment-specific tags
common_tags = {
    Environment     = local.environment
    ManagedBy       = "Terragrunt"
    Project         = "AWSPortfolio"
    Owner           = "InfraTeam"
}
}

