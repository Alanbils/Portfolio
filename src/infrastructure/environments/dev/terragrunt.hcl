# Development environment configuration
include {
  path = find_in_parent_folders()
}

locals {
  environment  = "dev"
  project_name = "dataeng"
  aws_region   = "us-east-1"
}

# Override inputs for the development environment
inputs = {
  # VPC configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # Data Lake configuration
  data_lake_bucket_name     = "dataeng-dev-data-lake"
  data_lake_retention_days  = 365
  
  # Redshift configuration
  redshift_cluster_type     = "single-node"
  redshift_node_type        = "dc2.large"
  redshift_number_of_nodes  = 1
  
  # EMR configuration
  emr_cluster_name          = "dataeng-dev-emr"
  emr_release_label         = "emr-6.5.0"
  emr_instance_type         = "m5.xlarge"
  emr_core_instance_count   = 2
  
  # Kinesis configuration
  kinesis_stream_name       = "dataeng-dev-ingestion-stream"
  kinesis_shard_count       = 1
  
  # Tags
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "DataEngineering"
  }
}