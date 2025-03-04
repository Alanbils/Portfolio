from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator

default_args = {
    'owner': 'data_engineering',
    'depends_on_past': False,
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'dbt_transformation_pipeline',
    default_args=default_args,
    description='Orchestrates dbt transformations and data quality checks',
    schedule_interval='0 */4 * * *',  # Every 4 hours
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['dbt', 'transformation', 'data_quality'],
) as dag:

    # Wait for new data in S3
    check_source_data = S3KeySensor(
        task_id='check_source_data',
        bucket_key='raw/orders/*.parquet',
        bucket_name='{{ var.value.data_lake_bucket }}',
        aws_conn_id='aws_default',
        timeout=3600,
        poke_interval=60,
    )

    # Load data from S3 to Redshift
    load_to_redshift = S3ToRedshiftOperator(
        task_id='load_to_redshift',
        schema='raw',
        table='orders',
        s3_bucket='{{ var.value.data_lake_bucket }}',
        s3_key='raw/orders/',
        redshift_conn_id='redshift_default',
        aws_conn_id='aws_default',
        copy_options=['FORMAT AS PARQUET'],
    )

    # Run dbt transformations
    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command='cd /opt/airflow/dbt && dbt run --profiles-dir .',
    )

    # Run data quality tests
    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command='cd /opt/airflow/dbt && dbt test --profiles-dir .',
    )

    # Generate dbt documentation
    dbt_docs = BashOperator(
        task_id='dbt_docs',
        bash_command='cd /opt/airflow/dbt && dbt docs generate --profiles-dir .',
    )

    # Define task dependencies
    check_source_data >> load_to_redshift >> dbt_run >> dbt_test >> dbt_docs
