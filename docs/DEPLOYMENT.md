# Deployment Guide

This guide walks through deploying the complete data engineering platform.

## Prerequisites

1. **AWS Account Setup**
```bash
# Configure AWS CLI
aws configure
```

2. **Required Tools**
```bash
# Install required tools
pip install -r requirements.txt
terraform -v  # Ensure Terraform >= 1.0.0
terragrunt -v # Ensure Terragrunt >= 0.36.0
```

## Step-by-Step Deployment

### 1. Infrastructure Deployment

```bash
# Navigate to dev environment
cd infrastructure/terragrunt/dev/us-east-1

# Initialize and deploy infrastructure
terragrunt run-all init
terragrunt run-all plan    # Review changes
terragrunt run-all apply   # Deploy infrastructure
```

Required environment variables:
```bash
export TF_VAR_project_prefix="your-project"
export TF_VAR_environment="dev"
export AWS_PROFILE="your-profile"
```

### 2. Data Pipeline Setup

#### 2.1 DBT Setup
```bash
# Navigate to dbt project
cd data-pipelines/dbt_analytics

# Install dependencies
pip install dbt-redshift

# Configure profiles.yml with your credentials
vim profiles.yml

# Test connection and run models
dbt debug
dbt run
```

#### 2.2 Airflow Setup
```bash
# Set up Airflow environment
export AIRFLOW_HOME=~/airflow
pip install apache-airflow[aws]

# Initialize Airflow database
airflow db init

# Copy DAGs
cp data-pipelines/airflow_dags/* ~/airflow/dags/

# Start Airflow (for local development)
airflow webserver -D
airflow scheduler -D
```

#### 2.3 Streaming Pipeline
```bash
# Deploy Kinesis processor
cd data-pipelines/streaming
zip -r processor.zip kinesis_processor.py
aws lambda update-function-code --function-name stream-processor --zip-file fileb://processor.zip
```

### 3. Data Quality Framework

#### 3.1 Great Expectations
```bash
# Initialize Great Expectations
cd data-quality/great_expectations
great_expectations init

# Configure datasource
great_expectations datasource new

# Run validations
great_expectations checkpoint run orders_suite
```

### 4. Monitoring Setup

```bash
# Deploy CloudWatch dashboards
aws cloudwatch put-dashboard \
    --dashboard-name data-quality-monitoring \
    --dashboard-body file://monitoring/dashboards/data_quality_dashboard.json

# Set up alerts
cd monitoring/alerts
terraform init
terraform apply
```

## Environment Variables Needed

Create a `.env` file with these variables:
```bash
# AWS Configuration
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Database Credentials
export DBT_HOST="your-redshift-host"
export DBT_USER="your-username"
export DBT_PASSWORD="your-password"

# Airflow Configuration
export AIRFLOW__CORE__FERNET_KEY="your-fernet-key"
export AIRFLOW__CORE__SQL_ALCHEMY_CONN="your-db-connection"

# Monitoring
export ALERT_EMAIL="your-email@example.com"
```

## CI/CD Setup

1. Add these secrets to your GitHub repository:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DBT_HOST`
   - `DBT_USER`
   - `DBT_PASSWORD`

2. Enable GitHub Actions in your repository

## Verification Steps

1. Check infrastructure:
```bash
terragrunt output  # Should show all resources
aws s3 ls         # Should list your buckets
```

2. Verify data pipeline:
```bash
dbt test          # All tests should pass
airflow dags list # Should show your DAGs
```

3. Monitor deployment:
- Check CloudWatch dashboards
- Verify Kinesis streams are receiving data
- Ensure Airflow DAGs are running

## Troubleshooting

Common issues and solutions:

1. **Infrastructure Deployment Fails**
   - Check AWS credentials
   - Verify IAM permissions
   - Review Terraform state

2. **DBT Issues**
   - Run `dbt debug` for connection issues
   - Check profiles.yml configuration
   - Verify Redshift access

3. **Airflow Problems**
   - Check logs: `~/airflow/logs`
   - Verify database connection
   - Ensure DAGs are properly configured

## Maintenance

Regular maintenance tasks:
1. Update dependencies monthly
2. Review and rotate credentials quarterly
3. Monitor CloudWatch metrics daily
4. Check data quality reports weekly
