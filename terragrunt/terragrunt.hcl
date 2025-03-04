/* 
  Root terragrunt.hcl configuration
  This file contains the root configuration for all environments and regions
*/

locals {
  # Parse the filepath to extract environment, region, and resource type
  path_components = regex(".*/(?P<environment>dev|staging|prod)/(?P<region>[\\w-]+)/(?P<resource>[\\w-]+)$", get_terragrunt_dir())
  
  environment    = local.path_components.environment
  region         = local.path_components.region
  resource_type  = local.path_components.resource
  
  # Common tags for all resources
  common_tags = {
    Environment = local.environment
    Project     = "AWSDataEngineering"
    ManagedBy   = "Terragrunt"
    Owner       = "DataTeam"
  }

  # Remote state configuration
  remote_state_bucket_prefix = "aws-data-engineering-terraform-state"
}

# Remote state configuration - uses S3 backend
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.remote_state_bucket_prefix}-${local.environment}"
    key            = "${local.region}/${local.resource_type}/terraform.tfstate"
    region         = "us-east-1"  # Region for the S3 bucket
    encrypt        = true
    dynamodb_table = "terraform-locks-${local.environment}"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}

# Generate version constraints
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
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

# Configure dependency paths
inputs = {
  environment = local.environment
  region      = local.region
}