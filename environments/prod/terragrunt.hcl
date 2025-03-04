# Production environment configuration
include {
  path = find_in_parent_folders()
}

locals {
  environment  = "prod"
  project_name = "dataeng"
  aws_region   = "us-east-1"
}

# Override inputs for the production environment
inputs = {
  # VPC configuration
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  
  # Data Lake configuration
  data_lake_bucket_name     = "dataeng-prod-data-lake"
  data_lake_retention_days  = 2555  # 7 years
  
  # Redshift configuration
  redshift_cluster_type     = "multi-node"
  redshift_node_type        = "ra3.4xlarge"
  redshift_number_of_nodes  = 4
  
  # EMR configuration
  emr_cluster_name          = "dataeng-prod-emr"
  emr_release_label         = "emr-6.5.0"
  emr_instance_type         = "r5.2xlarge"
  emr_core_instance_count   = 10
  
  # Kinesis configuration
  kinesis_stream_name       = "dataeng-prod-ingestion-stream"
  kinesis_shard_count       = 10
  
  # Enhanced monitoring
  enable_enhanced_monitoring = true
  alarm_email                = "data-alerts@example.com"
  
  # Tags
  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Project     = "DataEngineering"
  }
}