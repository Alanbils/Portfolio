# Root terragrunt.hcl configuration
# This configures common settings for all environments

# Generate providers block based on environment
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  
  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "Terraform"
      Project     = "DataEngineering"
    }
  }
}
EOF
}

# Configure Terraform backend for remote state management
remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.project_name}-${local.environment}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.aws_region}"
    encrypt        = true
    dynamodb_table = "${local.project_name}-${local.environment}-terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Define common inputs for all modules
inputs = {
  environment  = local.environment
  project_name = local.project_name
  region       = local.aws_region
  tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Project     = local.project_name
  }
}

# Extract locals from environment variables and parent configs
locals {
  # Default values, can be overridden by child terragrunt.hcl files
  environment  = "dev"
  project_name = "dataeng"
  aws_region   = "us-east-1"
}

# Enable dependency optimization
dependency_optimization_enabled = true

# Retry failed commands
retryable_errors = [
  "(?s).*error configuring S3 Backend.*",
  "(?s).*Error creating S3 bucket.*"
]

# Prevent excessively long command names
terraform_binary = "terraform"

# Skip validation for specific modules
skip_outputs = true