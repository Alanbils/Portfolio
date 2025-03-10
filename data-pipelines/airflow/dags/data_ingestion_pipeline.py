from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator
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
    'data_ingestion_pipeline',
    default_args=default_args,
    description='End-to-end data ingestion pipeline',
    schedule_interval='@daily',
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['ingestion', 'production'],
) as dag:

    # Check for new data
    check_source_data = S3KeySensor(
        task_id='check_source_data',
        bucket_key='raw/{{ds}}/*.parquet',
        bucket_name='{{ var.value.raw_bucket }}',
        aws_conn_id='aws_default',
        timeout=60 * 60,  # 1 hour
        poke_interval=5 * 60  # 5 minutes
    )

    # Run Glue ETL job
    transform_data = GlueJobOperator(
        task_id='transform_data',
        job_name='raw_to_processed_etl',
        script_location='s3://{{ var.value.scripts_bucket }}/glue/raw_to_processed.py',
        script_args={
            '--source_path': 's3://{{ var.value.raw_bucket }}/raw/{{ds}}/',
            '--target_path': 's3://{{ var.value.processed_bucket }}/processed/{{ds}}/',
            '--job_date': '{{ds}}'
        },
        aws_conn_id='aws_default'
    )

    # Load to Redshift
    load_to_warehouse = S3ToRedshiftOperator(
        task_id='load_to_warehouse',
        schema='public',
        table='fact_orders',
        s3_bucket='{{ var.value.processed_bucket }}',
        s3_key='processed/{{ds}}/orders.parquet',
        copy_options=['FORMAT AS PARQUET'],
        aws_conn_id='aws_default',
        redshift_conn_id='redshift_default'
    )

    # Log data quality metrics
    def log_metrics(**context):
        from great_expectations.data_context import DataContext
        
        # Initialize Great Expectations context
        context = DataContext(
            context_root_dir='/opt/airflow/great_expectations'
        )
        
        # Run validation
        batch_request = context.get_batch_request(
            datasource_name="redshift",
            data_connector_name="default_inferred_data_connector_name",
            data_asset_name="fact_orders",
            batch_identifiers={
                "partition": context['ds']
            }
        )
        
        context.run_validation_operator(
            "action_list_operator",
            assets_to_validate=[batch_request],
            run_name=f"fact_orders_validation_{context['ds']}"
        )

    validate_data = PythonOperator(
        task_id='validate_data',
        python_callable=log_metrics,
        provide_context=True
    )

    # Define pipeline flow
    check_source_data >> transform_data >> load_to_warehouse >> validate_data
