include {
  path = find_in_parent_folders()
}

locals {
  # Parse the file path to extract environment and component
  env_vars = read_terragrunt_config(find_in_parent_folders())
  env      = local.env_vars.locals.environment
  region   = local.env_vars.locals.aws_region
  
  # Module-specific variables
  bucket_name = "data-platform-datalake-${local.env}"
}

# Specify the Terraform module to use
terraform {
  source = "../../../terraform/modules/data_lake"
}

# Dependencies (if any)
dependencies {
  paths = ["../networking"]
}

# Input variables specific to this module
inputs = {
  environment     = local.env
  region          = local.region
  
  # Data Lake configuration
  data_lake_bucket_name              = local.bucket_name
  enable_versioning                  = true
  enable_lifecycle_rules             = true
  transition_glacier_days            = 180
  transition_standard_ia_days        = 90
  expiration_days                    = 365
  
  # Access control
  block_public_access                = true
  enable_server_side_encryption      = true
  
  # Bucket structure
  raw_data_prefix                    = "raw/"
  processed_data_prefix              = "processed/"
  curated_data_prefix                = "curated/"
  
  # Tags
  additional_tags = {
    DataClassification = "Confidential"
    CostCenter         = "DE-${local.env}"
  }
}