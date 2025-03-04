/*
  Streaming configuration for dev environment in us-east-1
  This includes Kinesis Data Streams and Firehose
*/

# Include the environment-level terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Specify the Terraform module source
terraform {
  source = "../../../../terraform/modules/kinesis-streams"
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

dependency "etl" {
  config_path = "../etl"
  
  # Configure mock outputs for plan operations when etl hasn't been applied yet
  mock_outputs = {
    database_names = {
      raw = "dev_raw_db"
    }
  }
  
  skip_outputs = true
}

# Inputs specific to this module for this environment/region
inputs = {
  # Pass outputs from dependencies
  data_lake_bucket_arn  = dependency.data_lake.outputs.data_lake_bucket_arn
  
  # Dev-specific stream configuration - smaller and cheaper
  data_streams = {
    clickstream = {
      shard_count      = 1
      retention_period = 24
      on_demand_mode   = false
    },
    transactions = {
      shard_count      = 1
      retention_period = 24
      on_demand_mode   = false
    }
  }
  
  # Dev configuration
  firehose_buffer_size     = 1
  firehose_buffer_interval = 60
  enable_data_format_conversion = false
  enable_processing = false
  
  # Override common tags with specific ones for this component
  tags = {
    Component = "KinesisStreams"
    DataOwner = "DataEngineering"
  }
}