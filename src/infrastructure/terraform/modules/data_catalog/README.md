# AWS Glue Data Catalog Module

This Terraform module creates and manages AWS Glue Data Catalog resources for the data engineering platform.

## Features

- Creates a Glue catalog database for storing metadata
- Configures a Glue crawler to automatically discover schema for data in S3
- Sets up IAM roles and permissions for Glue services
- Configures crawler schedules and behavior

## Usage

```hcl
module "data_catalog" {
  source = "../../../terraform/modules/data_catalog"

  region          = "us-west-2"
  environment     = "dev"
  database_name   = "analytics"
  crawler_name    = "raw-data-crawler"
  data_lake_bucket = "my-company-data-lake-dev"
  
  tags = {
    Owner       = "data-engineering-team"
    Environment = "dev"
    Terraform   = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14.0 |
| aws | >= 3.50.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| region | AWS region to deploy resources | string | us-west-2 | no |
| environment | Environment (dev, staging, prod) | string | n/a | yes |
| database_name | Name of the Glue catalog database | string | data_catalog | no |
| crawler_name | Name of the Glue crawler | string | data-lake-crawler | no |
| crawler_schedule | Cron schedule for the crawler | string | cron(0 0 * * ? *) | no |
| table_prefix | Prefix to add to tables created by the crawler | string | raw_ | no |
| data_lake_bucket | S3 bucket name for the data lake | string | n/a | yes |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| glue_database_name | Name of the AWS Glue catalog database |
| glue_crawler_name | Name of the AWS Glue crawler |
| glue_service_role_arn | ARN of the IAM role for Glue services |
| database_arn | ARN of the Glue catalog database |
| database_id | ID of the Glue catalog database |