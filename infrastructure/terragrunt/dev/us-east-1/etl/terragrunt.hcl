/*
  ETL configuration for dev environment in us-east-1
  This includes AWS Glue catalog and ETL jobs
*/

# Include the environment-level terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Specify the Terraform module source
terraform {
  source = "../../../../terraform/modules/glue-catalog"
}

# Dependencies on other terragrunt configurations
dependency "data_lake" {
  config_path = "../data-lake"
  
  # Configure mock outputs for plan operations when data-lake hasn't been applied yet
  mock_outputs = {
    data_lake_bucket_arn  = "arn:aws:s3:::mock-data-lake-bucket"
    data_lake_bucket_name = "mock-data-lake-bucket"
  }
}

# Inputs specific to this module for this environment/region
inputs = {
  # Pass outputs from dependencies
  data_lake_bucket_arn  = dependency.data_lake.outputs.data_lake_bucket_arn
  data_lake_bucket_name = dependency.data_lake.outputs.data_lake_bucket_name
  
  # ETL-specific inputs
  crawler_schedule = null  # No schedule for dev, trigger crawlers manually
  
  # Override common tags with specific ones for this component
  tags = {
    Component = "GlueCatalog"
    DataOwner = "DataEngineering"
  }
}