include {
  path = find_in_parent_folders()
}

locals {
  # Parse the file path to extract environment and component
  env_vars = read_terragrunt_config(find_in_parent_folders())
  env      = local.env_vars.locals.environment
  region   = local.env_vars.locals.aws_region
  
  # Module-specific variables
  cluster_identifier = "data-platform-warehouse-${local.env}"
}

# Specify the Terraform module to use
terraform {
  source = "../../../terraform/modules/data_warehouse"
}

# Dependencies (if any)
dependencies {
  paths = ["../networking", "../data-lake"]
}

# Input variables specific to this module
inputs = {
  environment        = local.env
  region             = local.region
  
  # Redshift configuration
  cluster_identifier = local.cluster_identifier
  database_name      = "analytics"
  master_username    = "admin"
  
  # Node configuration
  node_type          = local.env == "prod" ? "ra3.4xlarge" : "ra3.xlplus"
  cluster_type       = local.env == "prod" ? "multi-node" : "single-node"
  number_of_nodes    = local.env == "prod" ? 4 : 1
  
  # Network configuration
  vpc_id             = dependency.networking.outputs.vpc_id
  subnet_ids         = dependency.networking.outputs.private_subnet_ids
  
  # Security
  encrypted          = true
  publicly_accessible = false
  
  # Maintenance
  automated_snapshot_retention_period = 7
  maintenance_window                  = "sat:05:00-sat:06:00"
  
  # Tags
  additional_tags = {
    DataClassification = "Confidential"
    CostCenter         = "DE-${local.env}"
  }
}