from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.redshift import RedshiftSQLOperator
from airflow.providers.dbt.operators.dbt import DbtRunOperator
from great_expectations_provider.operators.great_expectations import GreatExpectationsOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data_engineering',
    'depends_on_past': False,
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'data_quality_pipeline',
    default_args=default_args,
    description='End-to-end data pipeline with quality checks',
    schedule_interval='0 */4 * * *',  # Every 4 hours
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['data-quality', 'production'],
) as dag:

    # Run dbt models
    dbt_run = DbtRunOperator(
        task_id='dbt_run',
        profiles_dir='/opt/airflow/dbt',
        target='prod',
        dir='/opt/airflow/dbt/dbt_analytics'
    )

    # Run data quality checks
    data_quality_check = GreatExpectationsOperator(
        task_id='data_quality_check',
        expectation_suite_name='orders_suite',
        batch_kwargs={
            'datasource': 'redshift_data',
            'table': 'orders'
        },
        data_context_root_dir='/opt/airflow/great_expectations'
    )

    # Generate data quality reports
    generate_docs = PythonOperator(
        task_id='generate_docs',
        python_callable=lambda: None  # Placeholder for documentation generation
    )

    # Monitor data freshness
    check_freshness = RedshiftSQLOperator(
        task_id='check_freshness',
        sql="""
        SELECT 
            table_name,
            MAX(last_update) as last_update,
            CASE 
                WHEN MAX(last_update) < CURRENT_TIMESTAMP - INTERVAL '4 hours'
                THEN 'STALE'
                ELSE 'FRESH'
            END as freshness_status
        FROM data_freshness_log
        GROUP BY table_name;
        """
    )

    # Define pipeline flow
    dbt_run >> data_quality_check >> generate_docs >> check_freshness
