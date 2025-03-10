# Modern Data Engineering Portfolio

This repository showcases a production-grade data engineering platform implementing modern data stack practices and cloud-native architectures on AWS.

## 🏗️ Repository Structure

```
portfolio/
├── infrastructure/           # Infrastructure as Code (IaC)
│   ├── terraform/           # Reusable Terraform modules
│   │   ├── modules/        # Core infrastructure modules
│   │   │   ├── data-lake/  # S3, Glue, Athena setup
│   │   │   ├── streaming/  # Kinesis setup
│   │   │   └── warehouse/  # Redshift setup
│   │   └── live/          # Live infrastructure configs
│   └── terragrunt/         # Environment configurations
│       ├── dev/           # Development environment
│       ├── staging/       # Staging environment
│       └── prod/          # Production environment
├── data-pipelines/         # Data Processing Components
│   ├── dbt/               # dbt transformations
│   │   ├── models/        # Data models (staging, marts)
│   │   ├── tests/         # Data quality tests
│   │   └── docs/          # Documentation
│   ├── airflow/           # Airflow DAGs
│   │   ├── dags/          # Pipeline definitions
│   │   └── plugins/       # Custom operators
│   └── streaming/         # Real-time processing
│       └── processors/    # Stream processors
├── data-quality/          # Data Quality Framework
│   ├── great_expectations/ # Data validation
│   └── dbt_tests/         # Custom dbt tests
├── monitoring/            # Observability Stack
│   ├── dashboards/        # CloudWatch dashboards
│   └── alerts/           # Alert configurations
└── notebooks/            # Analysis & Prototyping
    └── quality/          # Data quality notebooks
```

## 🚀 Key Features

### Data Processing
- **Modern Data Stack**: dbt for transformations, Airflow for orchestration
- **Data Lake**: S3-based with Glue catalog and Athena querying
- **Data Warehouse**: Redshift optimization and best practices
- **Streaming Pipeline**: Real-time processing with Kinesis
- **ETL Framework**: AWS Glue, Lambda, and Step Functions

### Infrastructure & DevOps
- **IaC**: Terraform modules with Terragrunt for multi-environment management
- **CI/CD**: Automated testing, documentation, and deployment
- **Security**: IAM roles, encryption, and secure credential management
- **Monitoring**: CloudWatch dashboards and alerts

### Data Quality & Governance
- **Testing**: dbt tests and Great Expectations
- **Documentation**: Auto-generated data catalogs
- **Observability**: Real-time quality monitoring

## 🛠️ Technologies

- **Cloud**: AWS (S3, Glue, Athena, Redshift, Kinesis, Lambda)
- **Processing**: dbt, Apache Spark, Python
- **Orchestration**: Airflow
- **DevOps**: Terraform, GitHub Actions
- **Quality**: Great Expectations, dbt Testing

## 📚 Getting Started

1. **Infrastructure Setup**
```bash
cd infrastructure/terragrunt/dev
terragrunt run-all apply
```

2. **Data Pipeline Development**
```bash
cd data-pipelines/dbt
dbt deps
dbt run
```

3. **Quality Checks**
```bash
cd data-quality/great_expectations
great_expectations checkpoint run
```

## 📊 Project Components

### /infrastructure
- Terraform modules for AWS resources
- Environment-specific configurations
- Network and security settings

### /data-pipelines
- dbt models and transformations
- Airflow DAG definitions
- Streaming pipeline configurations

### /data-quality
- Data quality test suites
- Validation frameworks
- Quality monitoring

### /monitoring
- CloudWatch dashboards
- Alert configurations
- Logging setup

### /notebooks
- Data analysis notebooks
- Pipeline prototypes
- Documentation examples

## 🔄 Data Flow

1. Raw data lands in S3 data lake from various sources
2. AWS Glue catalogs the data and makes it available to query engines
3. Raw data is loaded into Redshift for high-performance analytics
4. dbt models transform raw data into:
   - Clean and validated staging models
   - Core business entities (dimensions and facts)
   - Department-specific analytics models

## 📖 Documentation

Detailed documentation for each component is available in the `/docs` directory:
- Architecture diagrams
- Setup guides
- Best practices
- Troubleshooting guides

## ✨ Best Practices

This repository follows these best practices:
- **DRY code** using Terragrunt and modules
- **State management** with remote state in S3
- **Security** with least privilege principles
- **Testing** data quality with dbt and Great Expectations
- **CI/CD** for both infrastructure and analytics code
- **Documentation** as code
