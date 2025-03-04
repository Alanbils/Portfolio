# AWS Data Engineering Infrastructure

This repository contains Terraform and Terragrunt code to deploy a complete AWS data engineering infrastructure.

## Architecture

This infrastructure includes:

- **Networking**: VPC, subnets, security groups, and NAT gateways
- **Data Lake**: S3 buckets with appropriate policies
- **Data Catalog & ETL**: AWS Glue jobs and crawlers
- **Data Warehouse**: Amazon Redshift cluster
- **Big Data Processing**: EMR clusters
- **Streaming**: Kinesis streams and analytics
- **Security**: IAM roles and policies
- **Monitoring**: CloudWatch dashboards and alarms

## Repository Structure

```
.
├── environments/            # Infrastructure code for each environment
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment
│   └── prod/                # Production environment
├── modules/                 # Reusable Terraform modules
├── terragrunt/              # Terragrunt configuration
└── docs/                    # Documentation
```

## Getting Started

### Prerequisites

- Terraform >= 0.14.0
- Terragrunt >= 0.28.0
- AWS CLI configured with appropriate credentials

### Deployment

To deploy the infrastructure:

1. Navigate to the environment directory you want to deploy
2. Run `terragrunt run-all plan` to see the changes that will be applied
3. Run `terragrunt run-all apply` to apply the changes

## Best Practices

This repository follows these best practices:

- **DRY code** using Terragrunt and modules
- **State management** with remote state in S3
- **Parameterization** for environment-specific values
- **Versioning** of modules and configurations
- **Security** with least privilege principles