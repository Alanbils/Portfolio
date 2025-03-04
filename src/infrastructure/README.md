# Infrastructure as Code

This directory contains all Infrastructure as Code (IaC) components for the data engineering platform.

## Overview

The infrastructure code is organized into three main components:

1. **Terraform Modules**: Reusable infrastructure components that define AWS resources
2. **Terragrunt Configuration**: Environment-specific configurations and orchestration
3. **Environment Deployments**: Separate deployment configurations for development, staging, and production

## Directory Structure

```
infrastructure/
├── terraform/             # Reusable Terraform modules
│   ├── modules/           # Individual infrastructure modules
│   │   ├── data_lake/     # S3 data lake configuration
│   │   ├── data_warehouse/ # Redshift configuration
│   │   ├── networking/    # VPC and networking components
│   │   └── ...
├── terragrunt/            # Terragrunt orchestration
│   ├── modules/           # Terragrunt module configurations
│   └── terragrunt.hcl     # Root Terragrunt configuration
└── environments/          # Environment-specific deployments
    ├── dev/               # Development environment
    ├── staging/           # Staging environment
    └── prod/              # Production environment
```

## Key Features

- **Multi-environment Support**: Separate configurations for dev, staging, and production
- **Infrastructure Testing**: Automated tests for infrastructure code
- **State Management**: Remote state management with S3 and DynamoDB
- **Modular Design**: Reusable infrastructure components
- **Security Best Practices**: Secure defaults and least privilege access

## Usage

### Prerequisites

- Terraform ≥ 0.14.0
- Terragrunt ≥ 0.28.0
- AWS CLI configured with appropriate credentials

### Deployment

For a complete deployment of all infrastructure:

```bash
# Navigate to the environment directory
cd environments/dev

# Plan all changes
terragrunt run-all plan

# Apply all changes
terragrunt run-all apply
```

For deploying individual components:

```bash
# Navigate to the component directory
cd environments/dev/networking

# Plan and apply changes for just this component
terragrunt plan
terragrunt apply
```

## Security Considerations

- All sensitive data is stored in AWS Secrets Manager or SSM Parameter Store
- All resources use encryption at rest by default
- Least privilege IAM roles are defined for all components
- Network security follows AWS best practices with private subnets and security groups

## Contribution Guidelines

When contributing to the infrastructure code:

1. Create a feature branch for your changes
2. Run `terraform fmt` and `terraform validate` before committing
3. Add tests for any new modules or significant changes
4. Create a pull request with a clear description of the changes