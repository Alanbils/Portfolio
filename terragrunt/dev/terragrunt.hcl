/*
  Development environment configuration
  This sets environment-specific variables for the dev environment
*/

# Include the root terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

locals {
  # Dev-specific variables
  environment_config = {
    # Common resource configurations for dev
    enable_detailed_monitoring = false
    instance_type              = "t3.medium"
    max_capacity               = 2
    min_capacity               = 1
  }
}

# Pass environment-specific inputs to the terraform modules
inputs = merge(
  local.environment_config,
  {
    # Additional dev-specific variables
    is_production              = false
    enable_deletion_protection = false
    retention_days             = 7
  }
)