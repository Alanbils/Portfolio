#!/usr/bin/env python3
"""
Tests for the orders_transformer.py module.
"""

import os
import sys
import unittest
from datetime import datetime, date
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, DateType

# Add the parent directory to the path so we can import the module
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from spark.orders_transformer import (
    clean_orders_data,
    enrich_orders_data
)

class OrdersTransformerTest(unittest.TestCase):
    """Test cases for orders_transformer.py"""

    @classmethod
    def setUpClass(cls):
        """Create a Spark session for all tests"""
        cls.spark = SparkSession.builder \
            .appName("OrdersTransformerTest") \
            .master("local[2]") \
            .getOrCreate()
        
        # Define the schema for test data
        cls.schema = StructType([
            StructField("order_id", StringType(), False),
            StructField("customer_id", IntegerType(), True),
            StructField("order_date", DateType(), True),
            StructField("order_status", StringType(), True),
            StructField("order_total", DoubleType(), True)
        ])
        
        # Create sample data
        cls.test_data = [
            ("ORD001", 1001, date(2023, 1, 15), "completed", 125.99),
            ("ORD002", 1002, date(2023, 1, 16), "processing", 85.50),
            ("ORD003", 1001, date(2023, 1, 20), "completed", 45.25),
            ("ORD004", 1003, date(2023, 1, 22), "cancelled", 210.75),
            ("ORD005", 1004, date(2023, 1, 25), "completed", 35.00),
            ("ORD006", None, date(2023, 1, 27), None, 75.25),
            ("ORD007", 1005, date(2023, 1, 30), "completed", 190.50),
            ("ORD008", 1006, date(2023, 2, 1), "processing", -10.00)  # Invalid order with negative total
        ]
        
        # Create DataFrame
        cls.orders_df = cls.spark.createDataFrame(cls.test_data, cls.schema)

    @classmethod
    def tearDownClass(cls):
        """Stop the Spark session"""
        cls.spark.stop()

    def test_clean_orders_data(self):
        """Test that clean_orders_data properly handles null values and filters invalid orders"""
        cleaned_df = clean_orders_data(self.orders_df)
        
        # Check row count (should be 7, with the negative order filtered out)
        self.assertEqual(cleaned_df.count(), 7)
        
        # Check that missing values were handled
        filled_values = cleaned_df.filter("customer_id = -1 OR order_status = 'unknown'").count()
        self.assertEqual(filled_values, 1)  # Only one row had nulls in these columns
        
        # Check that the days_since_order column was added
        self.assertTrue("days_since_order" in cleaned_df.columns)
        
        # Check that negative order totals were filtered out
        negative_orders = cleaned_df.filter("order_total < 0").count()
        self.assertEqual(negative_orders, 0)

    def test_enrich_orders_data(self):
        """Test that enrich_orders_data adds the expected derived columns"""
        # First clean the data
        cleaned_df = clean_orders_data(self.orders_df)
        
        # Then enrich it
        enriched_df = enrich_orders_data(cleaned_df)
        
        # Check that the order_size_category column was added
        self.assertTrue("order_size_category" in enriched_df.columns)
        
        # Check that the processing_timestamp column was added
        self.assertTrue("processing_timestamp" in enriched_df.columns)
        
        # Check that order categories are correctly assigned
        small_orders = enriched_df.filter("order_size_category = 'small'").count()
        medium_orders = enriched_df.filter("order_size_category = 'medium'").count()
        large_orders = enriched_df.filter("order_size_category = 'large'").count()
        
        # Based on our test data:
        # Small (<=25): 0
        # Medium (>25 and <=100): 3 (ORD003, ORD005, ORD006)
        # Large (>100): 4 (ORD001, ORD002, ORD004, ORD007)
        self.assertEqual(small_orders, 0)
        self.assertEqual(medium_orders, 3)
        self.assertEqual(large_orders, 4)


if __name__ == "__main__":
    unittest.main()