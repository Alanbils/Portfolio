# This file defines AWS account information for each environment
# These are dummy account IDs for portfolio demonstration purposes

locals {
# Map of environment names to AWS account IDs
account_ids = {
    dev     = "123456789012"
    staging = "234567890123"
    prod    = "345678901234"
}

# Map of environment names to account names (for tagging and identification)
account_names = {
    dev     = "development"
    staging = "staging"
    prod    = "production"
}

# Get the account ID for the current environment (determined by path)
account_id   = local.account_ids[local.environment]
account_name = local.account_names[local.environment]

# Extract environment name from the file path
# The path is expected to have the environment as the first directory
path_components = split("/", path_relative_to_include())
environment     = path_components[0]
}

