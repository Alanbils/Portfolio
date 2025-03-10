/*
  Production environment configuration
  This sets environment-specific variables for the prod environment
*/

# Include the root terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

locals {
  # Production-specific variables
  environment_config = {
    # Common resource configurations for production
    enable_detailed_monitoring = true
    instance_type              = "m5.xlarge"
    max_capacity               = 8
    min_capacity               = 2
  }
}

# Pass environment-specific inputs to the terraform modules
inputs = merge(
  local.environment_config,
  {
    # Additional production-specific variables
    is_production              = true
    enable_deletion_protection = true
    retention_days             = 30
    multi_az                   = true
    enable_encryption          = true
  }
)