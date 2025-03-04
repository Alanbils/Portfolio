# This file defines AWS region information

locals {
# Primary AWS region for deployment
aws_region = "us-east-1"

# Map of regions to availability zones
availability_zones = {
    "us-east-1" = ["us-east-1a", "us-east-1b", "us-east-1c"]
    "us-west-2" = ["us-west-2a", "us-west-2b", "us-west-2c"]
    "eu-west-1" = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

# Get availability zones for the current region
azs = local.availability_zones[local.aws_region]

# Region short names (for naming resources)
region_short_names = {
    "us-east-1" = "use1"
    "us-west-2" = "usw2"
    "eu-west-1" = "euw1"
}

# Get the short name for the current region
region_short = local.region_short_names[local.aws_region]
}

