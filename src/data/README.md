# Data

This directory contains all data processing and analytics components:

- **dbt/**: Data build tool (dbt) models for analytics engineering
- **processing/**: Scripts and configurations for batch data processing
- **streaming/**: Configuration and code for real-time data streaming

## Components

### dbt

The dbt directory contains the analytics engineering code that transforms raw data into business-ready datasets:

- **analyses/**: Ad-hoc analytical queries
- **macros/**: Reusable SQL snippets
- **models/**: Core data transformation logic
  - **staging/**: Models for source data
  - **marts/**: Business-defined data models
- **seeds/**: Static reference data

### Processing

Data processing scripts and configuration for batch data workloads.

### Streaming

Configuration and code for real-time data streaming pipelines.