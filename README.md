# AWS Data Engineering Infrastructure

This repository contains Terraform and Terragrunt code to deploy a complete AWS data engineering infrastructure with dbt models for analytics engineering.

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
- **Analytics Engineering**: dbt models for transforming raw data into analytics-ready datasets

## Repository Structure

```
.
├── environments/            # Infrastructure code for each environment
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment
│   └── prod/                # Production environment
├── models/                  # dbt models for analytics engineering
│   └── dbt/                 # dbt project files
│       ├── analyses/        # Ad-hoc analytical queries
│       ├── macros/          # Reusable SQL snippets
│       ├── models/          # Core data transformation logic
│       │   ├── staging/     # Models for source data
│       │   └── marts/       # Business-defined data models
│       └── seeds/           # Static reference data
├── modules/                 # Reusable Terraform modules
├── terragrunt/              # Terragrunt configuration
└── docs/                    # Documentation
```

## Getting Started

### Prerequisites

- Terraform >= 0.14.0
- Terragrunt >= 0.28.0
- dbt >= 1.3.0
- AWS CLI configured with appropriate credentials

### Infrastructure Deployment

To deploy the infrastructure:

1. Navigate to the environment directory you want to deploy
2. Run `terragrunt run-all plan` to see the changes that will be applied
3. Run `terragrunt run-all apply` to apply the changes

### Analytics Deployment

To deploy the dbt models:

1. Set environment variables for Redshift connection:
   ```
   export REDSHIFT_HOST=yourhost.region.redshift.amazonaws.com
   export REDSHIFT_USER=your_user
   export REDSHIFT_PASSWORD=your_password
   ```
2. Navigate to the `models/dbt` directory
3. Run `dbt deps` to install dependencies
4. Run `dbt run` to build all models

## Data Flow

1. Raw data lands in S3 data lake from various sources
2. AWS Glue catalogs the data and makes it available to query engines
3. Raw data is loaded into Redshift for high-performance analytics
4. dbt models transform raw data into:
   - Clean and validated staging models
   - Core business entities (dimensions and facts)
   - Department-specific analytics models

## Best Practices

This repository follows these best practices:

- **DRY code** using Terragrunt and modules
- **State management** with remote state in S3
- **Parameterization** for environment-specific values
- **Versioning** of modules and configurations
- **Security** with least privilege principles
- **Testing** data quality with dbt tests
- **CI/CD** for both infrastructure and analytics code
- **Documentation** for both infrastructure and analytics code