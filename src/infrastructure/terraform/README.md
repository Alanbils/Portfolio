# Terraform Modules

This directory contains reusable Terraform modules used throughout the data engineering infrastructure.

## Modules

The modules follow AWS best practices and are designed to be composable and reusable across different environments:

- `data_lake`: S3 buckets with appropriate lifecycle policies and access controls
- `data_warehouse`: Redshift cluster and supporting components
- `data_catalog`: Glue databases, crawlers, and catalog configuration
- `big_data`: EMR cluster configurations and bootstrap scripts
- `networking`: VPC, subnets, security groups, and transit configurations
- `security`: IAM roles, policies, and security configurations
- `monitoring`: CloudWatch dashboards, alarms, and monitoring infrastructure
- `streaming`: Kinesis streams and analytics applications

## Usage

Each module includes:
- Documentation in its README
- Input and output variables
- Examples of common use cases

To use these modules in your Terragrunt configurations, refer to them with the appropriate source path:

```hcl
terraform {
  source = "../../../terraform/modules/data_lake"
}
```