/*
  Data Lake configuration for dev environment in us-east-1
*/

# Include the environment-level terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Specify the Terraform module source
terraform {
  source = "../../../../terraform/modules/s3-data-lake"
}

# Dependencies (if any)
# dependencies {
#   paths = ["../vpc", "../security-groups"]
# }

# Inputs specific to this module for this environment/region
inputs = {
  # Additional inputs specific to data lake in dev environment
  enable_intelligent_tiering = true
  
  # Override common tags with specific ones for this component
  tags = {
    Component   = "DataLake"
    DataOwner   = "DataEngineering"
    Sensitivity = "Confidential"
  }
}