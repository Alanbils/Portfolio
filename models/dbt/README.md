# AWS Analytics dbt Project

This directory contains the dbt (data build tool) models for transforming raw data in Amazon Redshift into analytics-ready datasets.

## Project Structure

```
aws_analytics/
├── analyses/              # Ad-hoc analytical SQL queries
├── macros/                # Reusable SQL snippets and utility functions
├── models/                # Core data transformation logic
│   ├── staging/           # Models that clean and standardize source data
│   ├── marts/             # Business-defined data models
│       ├── core/          # Core business entities (dimensions and facts)
│       └── marketing/     # Marketing-specific models
├── seeds/                 # Static reference data
├── dbt_project.yml        # Project configuration
├── profiles.yml           # Connection profiles (not in version control)
└── packages.yml           # External package dependencies
```

## Data Flow

1. **Raw Data**: Data lands in the raw schema in Redshift from various sources (S3, Kinesis, etc.)
2. **Staging Models**: Clean and standardize source data with minimal transformations
3. **Core Models**: Build dimensional models (fact and dimension tables)
4. **Business Models**: Create department-specific models for specific use cases

## Testing

All models include data tests to ensure:
- Primary keys are unique and not null
- Foreign key relationships are valid
- Accepted values are within defined ranges
- Custom data quality checks where applicable

## Getting Started

### Prerequisites

- dbt installed (`pip install dbt-redshift`)
- AWS credentials with access to Redshift

### Setup

1. Clone this repository
2. Set environment variables for Redshift connection:
   ```
   export REDSHIFT_HOST=yourhost.region.redshift.amazonaws.com
   export REDSHIFT_USER=your_user
   export REDSHIFT_PASSWORD=your_password
   ```
3. Run `dbt deps` to install dependencies
4. Run `dbt seed` to load reference data
5. Run `dbt run` to build all models

## CI/CD Integration

This project integrates with CI/CD pipelines to:
1. Run tests on pull requests
2. Deploy models to development on merge to develop
3. Deploy models to production on merge to main

## Documentation

Generate documentation with:
```
dbt docs generate
dbt docs serve
```