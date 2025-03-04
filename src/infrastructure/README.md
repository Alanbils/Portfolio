# Infrastructure

This directory contains all infrastructure as code (IaC) components:

- **terraform/**: Reusable Terraform modules for various AWS services
- **terragrunt/**: Terragrunt configuration for managing deployments
- **environments/**: Environment-specific configurations (dev, staging, prod)

## Usage

Navigate to the specific environment directory and use Terragrunt to deploy:

```bash
cd environments/dev
terragrunt run-all plan
terragrunt run-all apply
```

Each environment contains modular components like networking, security, data storage, etc.