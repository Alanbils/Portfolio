# Terragrunt Configurations

This directory contains Terragrunt configurations that orchestrate the deployment of Terraform modules across multiple environments.

## Directory Structure

```
terragrunt/
├── modules/                  # Terragrunt component definitions
│   ├── data-lake/            # Terragrunt config for data lake components
│   ├── data-warehouse/       # Terragrunt config for data warehouse components
│   ├── networking/           # Terragrunt config for networking components
│   └── ...
└── terragrunt.hcl           # Root Terragrunt configuration
```

## Key Features

- **DRY Configuration**: Reduces duplication across environments using Terragrunt's inheritance
- **Remote State Management**: Configures S3 backends for each environment
- **Dependency Management**: Manages dependencies between infrastructure components
- **Parameterization**: Centralizes environment-specific parameters

## Usage

To deploy resources using these Terragrunt configurations:

1. Navigate to the appropriate environment directory:
   ```
   cd src/infrastructure/environments/dev
   ```

2. Plan all infrastructure changes:
   ```
   terragrunt run-all plan
   ```

3. Apply all infrastructure changes:
   ```
   terragrunt run-all apply
   ```

4. To work with individual components:
   ```
   cd src/infrastructure/environments/dev/networking
   terragrunt plan
   terragrunt apply
   ```

## Best Practices

- Always validate changes with `terragrunt plan` before applying
- Use `--terragrunt-non-interactive` flag for CI/CD pipelines
- Review the dependency graph with `terragrunt graph-dependencies`
- Use consistent naming conventions for all resources