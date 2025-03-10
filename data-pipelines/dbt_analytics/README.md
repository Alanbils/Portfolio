# Analytics dbt Project

This dbt project demonstrates modern data transformation practices and implements a robust analytics engineering workflow.

## Project Structure

```
dbt_analytics/
├── models/
│   ├── staging/      # Raw data models
│   ├── intermediate/ # Helper models
│   └── marts/        # Business-facing models
│       ├── core/     # Core business concepts
│       ├── marketing/
│       └── finance/
├── tests/            # Custom data tests
├── macros/          # Reusable SQL functions
└── snapshots/       # Type 2 SCD tracking
```

## Key Features

- Modular transformation logic with staging, intermediate, and mart layers
- Data quality tests and documentation
- Environment-based configurations (dev/prod)
- Integration with Redshift data warehouse
- Custom data quality tests

## Getting Started

1. Install dependencies:
```bash
pip install dbt-redshift
```

2. Set up environment variables:
```bash
export DBT_HOST=your-redshift-host
export DBT_USER=your-username
export DBT_PASSWORD=your-password
```

3. Run the project:
```bash
dbt run
dbt test
```

## Data Quality

- Source freshness checks
- Schema tests (uniqueness, not-null)
- Custom business logic tests
- Documentation coverage requirements

## Best Practices Implemented

- Clear model organization (staging → marts)
- Consistent naming conventions
- Incremental processing where applicable
- Environment-specific configurations
- Version controlled schema changes
