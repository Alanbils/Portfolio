#!/usr/bin/env python3
"""
Orders Data Transformer

This Spark job transforms raw orders data into a processed format for analytics.
It cleans data, applies transformations, and writes the result to the processed zone.
"""

import sys
import logging
from datetime import datetime
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, datediff, current_date, when, lit, udf
from pyspark.sql.types import StringType, DoubleType, IntegerType

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def create_spark_session():
    """Create and return a Spark session configured for this job."""
    return (SparkSession
            .builder
            .appName("OrdersTransformer")
            .config("spark.sql.sources.partitionOverwriteMode", "dynamic")
            .enableHiveSupport()
            .getOrCreate())

def read_orders_data(spark, input_path):
    """Read raw orders data from S3."""
    logger.info(f"Reading orders data from {input_path}")
    return spark.read.parquet(input_path)

def clean_orders_data(orders_df):
    """Clean the orders data by handling nulls and formatting."""
    logger.info("Cleaning orders data")
    
    # Convert date strings to date type
    orders_cleaned = orders_df.withColumn("order_date", to_date(col("order_date"), "yyyy-MM-dd"))
    
    # Handle missing values
    orders_cleaned = orders_cleaned.na.fill({
        "order_status": "unknown",
        "order_total": 0.0,
        "customer_id": -1
    })
    
    # Filter out invalid orders (those with negative totals)
    orders_cleaned = orders_cleaned.filter(col("order_total") >= 0)
    
    # Add a days_since_order column
    orders_cleaned = orders_cleaned.withColumn(
        "days_since_order", 
        datediff(current_date(), col("order_date"))
    )
    
    return orders_cleaned

def enrich_orders_data(orders_df):
    """Enrich orders data with additional attributes."""
    logger.info("Enriching orders data")
    
    # Add order_size category based on total
    orders_enriched = orders_df.withColumn(
        "order_size_category",
        when(col("order_total") <= 25, "small")
        .when((col("order_total") > 25) & (col("order_total") <= 100), "medium")
        .when(col("order_total") > 100, "large")
        .otherwise("unknown")
    )
    
    # Add processing timestamp
    orders_enriched = orders_enriched.withColumn(
        "processing_timestamp", 
        lit(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    )
    
    return orders_enriched

def write_processed_data(orders_df, output_path):
    """Write the processed data to the target location, partitioned by year and month."""
    logger.info(f"Writing processed orders data to {output_path}")
    
    # Add year and month columns for partitioning
    orders_with_partitions = orders_df.withColumn(
        "year", col("order_date").substr(1, 4)
    ).withColumn(
        "month", col("order_date").substr(6, 2)
    )
    
    # Write the data in Parquet format, partitioned by year and month
    (orders_with_partitions.write
        .partitionBy("year", "month")
        .mode("overwrite")
        .parquet(output_path))
    
    logger.info("Orders data processing completed successfully")

def main():
    """Main ETL script execution."""
    if len(sys.argv) != 3:
        logger.error("Usage: orders_transformer.py <input_path> <output_path>")
        sys.exit(1)
        
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    spark = create_spark_session()
    
    try:
        # Execute the ETL pipeline
        orders_raw = read_orders_data(spark, input_path)
        orders_cleaned = clean_orders_data(orders_raw)
        orders_processed = enrich_orders_data(orders_cleaned)
        write_processed_data(orders_processed, output_path)
        
    except Exception as e:
        logger.error(f"Error processing orders data: {str(e)}")
        sys.exit(1)
    finally:
        spark.stop()

if __name__ == "__main__":
    main()