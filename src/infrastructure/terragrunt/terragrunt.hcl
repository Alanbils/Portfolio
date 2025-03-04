/* 
  Root terragrunt.hcl configuration file containing global settings
  that apply to all environments and components.
*/

locals {
  # Parse the path to extract the environment
  path_parts       = split("/", path_relative_to_include())
  environment      = length(path_parts) > 1 ? path_parts[0] : "dev"
  aws_region_map   = {
    dev     = "us-west-2"
    staging = "us-west-2"
    prod    = "us-east-1"
  }
  aws_region       = local.aws_region_map[local.environment]
  
  # Common tags for all resources
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terragrunt"
    Project     = "DataPlatform"
  }
}

# Configure Terragrunt to use S3 for backend state
remote_state {
  backend = "s3"
  
  config = {
    bucket         = "data-platform-terraform-state-${local.environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-lock-table-${local.environment}"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure provider version constraints
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  
  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "Terragrunt"
      Project     = "DataPlatform"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.60"
    }
  }
  required_version = ">= 0.14.0"
}
EOF
}

# Default inputs for all terraform modules
inputs = {
  environment = local.environment
  region      = local.aws_region
  tags        = local.common_tags
}

# Configure terraform version and download directory behavior
terraform {
  # Force Terraform to keep the .terraform directory in each component directory
  extra_arguments "disable_backend_init" {
    commands = ["init"]
    arguments = ["-get=true", "-upgrade=true"]
  }
}

# Configure retries for API rate limiting
retryable_errors = [
  "(?s).*Error creating.*throttling.*",
  "(?s).*Error updating.*throttling.*",
  "(?s).*Error reading.*connection reset by peer.*"
]

retry_max_attempts = 3
retry_sleep_interval_sec = 10