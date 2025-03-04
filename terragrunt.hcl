# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT ROOT CONFIGURATION
# This is the root terragrunt.hcl file that sets global configurations for all modules in this repository.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# terragrunt.hcl config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
# Extract account and region information
account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))

# Extract the variables we need for easy access
account_id   = local.account_vars.locals.account_id
account_name = local.account_vars.locals.account_name
aws_region   = local.region_vars.locals.aws_region
aws_profile  = local.account_vars.locals.aws_profile
environment  = local.env_vars.locals.environment

# Define common tags to be applied to all resources
common_tags = {
    Environment = local.environment
    Terraform   = "true"
    AccountName = local.account_name
    AccountId   = local.account_id
    Owner       = "portfolio-project"
    Project     = "terragrunt-aws-portfolio"
}
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL REMOTE STATE CONFIGURATION
# Configure Terragrunt to automatically store tfstate files in an S3 bucket with DynamoDB locking
# ---------------------------------------------------------------------------------------------------------------------

remote_state {
backend = "s3"

# Set backend configuration for storing terraform state files
config = {
    encrypt         = true
    bucket          = "terraform-state-${local.account_name}-${local.environment}-${local.aws_region}"
    key             = "${path_relative_to_include()}/terraform.tfstate"
    region          = local.aws_region
    dynamodb_table  = "terraform-locks-${local.account_name}-${local.environment}"  
    profile         = local.aws_profile
    
    # Enable server-side encryption for S3
    server_side_encryption_configuration {
    rule {
        apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
        }
    }
    }
    
    # Enable access logging for security auditing
    logging {
    target_bucket = "terraform-state-access-logs-${local.account_name}"
    target_prefix = "terraform-state-${local.account_name}-${local.environment}/"
    }
}

# Set remote state generation options
generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
}
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS PROVIDER CONFIGURATION
# Configure the AWS Provider with our desired region and reasonable defaults
# ---------------------------------------------------------------------------------------------------------------------

generate "provider" {
path      = "provider.tf"
if_exists = "overwrite_terragrunt"
contents  = <<EOF
provider "aws" {
region  = "${local.aws_region}"
profile = "${local.aws_profile}"

# Best practice security settings
default_tags {
    tags = ${jsonencode(local.common_tags)}
}

# Use these settings for enhanced security
assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/TerraformExecutionRole"
    session_name = "Terragrunt"
}
}

# Setting version constraints for providers
terraform {
required_providers {
    aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
    }
}
required_version = ">= 1.4.0"
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL DEPENDENCY MANAGEMENT
# This allows child modules to automatically refer to outputs from dependencies by name
# ---------------------------------------------------------------------------------------------------------------------

# Use this dependency block in child modules to get outputs from other modules
inputs = {
# Common variables for all resources
environment  = local.environment
aws_region   = local.aws_region
account_id   = local.account_id
common_tags  = local.common_tags

# Naming convention for resources
name_prefix  = "${local.account_name}-${local.environment}"
}

# ---------------------------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# These helper functions simplify configuration for child modules
# ---------------------------------------------------------------------------------------------------------------------

# Use this in child terragrunt.hcl files to merge parent and child inputs
terraform {
# Force Terraform to keep trying to acquire a lock for up to 20 minutes if someone else already has the lock
extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = [
    "-lock-timeout=20m"
    ]
}

# Set common variables for all commands
extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    arguments = [
    "-var-file=${get_parent_terragrunt_dir()}/common.tfvars",
    ]
}
}

# Skip creating these resources when the 'skip' tag is present
skip = tobool(get_env("TERRAGRUNT_SKIP", "false"))

