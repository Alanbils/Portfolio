# CLAUDE.md - Guide for working in this repository

## Commands
- **Terragrunt Plan (All)**: `cd terragrunt/dev && terragrunt run-all plan`
- **Terragrunt Apply (All)**: `cd terragrunt/dev && terragrunt run-all apply`
- **Terragrunt Plan (Single)**: `cd terragrunt/dev/us-east-1/data-lake && terragrunt plan`
- **Terragrunt Apply (Single)**: `cd terragrunt/dev/us-east-1/data-lake && terragrunt apply`
- **Terraform Format**: `terraform fmt -recursive`
- **Python Lint**: `flake8 pipelines/`
- **Python Format**: `black pipelines/`
- **Python Type Check**: `mypy pipelines/`

## Code Style Guidelines
- **Terraform/Terragrunt**: Use modules, consistent naming with snake_case, 2-space indentation
- **Python**: Follow PEP 8, use type hints, docstrings for all functions
- **AWS Resources**: Use consistent tagging (Environment, Project, Owner, ManagedBy)
- **Naming**: snake_case for Terraform/Python, PascalCase for CloudFormation/CDK
- **Comments**: Document non-obvious code, include purpose for all resources
- **Secrets**: Never hardcode credentials, use AWS Secrets Manager or Parameter Store
- **Error Handling**: Proper logging and try/except blocks in Python code
- **Idempotency**: Ensure all operations can be run multiple times safely

This repository demonstrates AWS data engineering solutions using Terragrunt for infrastructure.