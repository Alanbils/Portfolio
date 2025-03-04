#!/usr/bin/env python3
"""
Data Quality Validation Module

This module provides functions for performing data quality checks on datasets.
It supports checks for completeness, consistency, validity, and uniqueness.
"""

import logging
import pandas as pd
import numpy as np
from typing import Dict, List, Any, Tuple, Optional, Union
from pyspark.sql import DataFrame as SparkDataFrame
from pyspark.sql import functions as F
from pyspark.sql.types import StructType

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DataQualityChecker:
    """Class for performing data quality checks on Spark and Pandas DataFrames."""
    
    def __init__(self, is_spark: bool = True):
        """
        Initialize the DataQualityChecker.
        
        Args:
            is_spark: Boolean indicating if we're working with Spark DataFrames (True) 
                     or Pandas DataFrames (False)
        """
        self.is_spark = is_spark
        self.results = {}
    
    def check_missing_values(self, 
                            df: Union[SparkDataFrame, pd.DataFrame], 
                            columns: Optional[List[str]] = None,
                            threshold: float = 0.05) -> Dict[str, Any]:
        """
        Check for missing values in the specified columns.
        
        Args:
            df: DataFrame to check
            columns: List of columns to check (if None, checks all columns)
            threshold: Maximum acceptable percentage of missing values
            
        Returns:
            Dictionary with results of the check
        """
        logger.info("Checking for missing values")
        
        if columns is None:
            if self.is_spark:
                columns = df.columns
            else:
                columns = df.columns.tolist()
        
        results = {}
        failed_columns = []
        
        for col in columns:
            if self.is_spark:
                total_count = df.count()
                null_count = df.filter(F.col(col).isNull()).count()
            else:
                total_count = len(df)
                null_count = df[col].isnull().sum()
            
            null_percentage = null_count / total_count if total_count > 0 else 0
            
            results[col] = {
                'null_count': null_count,
                'total_count': total_count,
                'null_percentage': null_percentage,
                'passed': null_percentage <= threshold
            }
            
            if not results[col]['passed']:
                failed_columns.append(col)
        
        check_result = {
            'check_name': 'missing_values',
            'column_results': results,
            'failed_columns': failed_columns,
            'overall_passed': len(failed_columns) == 0
        }
        
        self.results['missing_values'] = check_result
        return check_result
    
    def check_uniqueness(self, 
                        df: Union[SparkDataFrame, pd.DataFrame], 
                        columns: List[str],
                        should_be_unique: bool = True) -> Dict[str, Any]:
        """
        Check if values in the specified columns are unique.
        
        Args:
            df: DataFrame to check
            columns: List of columns to check uniqueness
            should_be_unique: Whether the columns should contain unique values
            
        Returns:
            Dictionary with results of the check
        """
        logger.info(f"Checking uniqueness for columns: {columns}")
        
        if self.is_spark:
            total_count = df.count()
            distinct_count = df.select(columns).distinct().count()
        else:
            total_count = len(df)
            distinct_count = df.drop_duplicates(subset=columns).shape[0]
        
        is_unique = distinct_count == total_count
        
        check_result = {
            'check_name': 'uniqueness',
            'columns': columns,
            'total_count': total_count,
            'distinct_count': distinct_count,
            'is_unique': is_unique,
            'passed': is_unique == should_be_unique
        }
        
        self.results['uniqueness'] = check_result
        return check_result
    
    def check_value_ranges(self, 
                          df: Union[SparkDataFrame, pd.DataFrame],
                          checks: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """
        Check if values in columns fall within specified ranges.
        
        Args:
            df: DataFrame to check
            checks: Dictionary mapping column names to range specifications
                Example: {'age': {'min': 0, 'max': 120}}
                
        Returns:
            Dictionary with results of the check
        """
        logger.info("Checking value ranges")
        
        results = {}
        failed_columns = []
        
        for column, range_spec in checks.items():
            min_val = range_spec.get('min')
            max_val = range_spec.get('max')
            
            if self.is_spark:
                if min_val is not None and max_val is not None:
                    out_of_range = df.filter(
                        (F.col(column) < min_val) | (F.col(column) > max_val)
                    ).count()
                elif min_val is not None:
                    out_of_range = df.filter(F.col(column) < min_val).count()
                elif max_val is not None:
                    out_of_range = df.filter(F.col(column) > max_val).count()
                else:
                    out_of_range = 0
                
                total_count = df.count()
            else:
                if min_val is not None and max_val is not None:
                    out_of_range = df[(df[column] < min_val) | (df[column] > max_val)].shape[0]
                elif min_val is not None:
                    out_of_range = df[df[column] < min_val].shape[0]
                elif max_val is not None:
                    out_of_range = df[df[column] > max_val].shape[0]
                else:
                    out_of_range = 0
                
                total_count = len(df)
            
            in_range_percentage = 1 - (out_of_range / total_count if total_count > 0 else 0)
            threshold = range_spec.get('threshold', 1.0)  # Default threshold: 100% must be in range
            
            results[column] = {
                'min': min_val,
                'max': max_val,
                'out_of_range_count': out_of_range,
                'total_count': total_count,
                'in_range_percentage': in_range_percentage,
                'threshold': threshold,
                'passed': in_range_percentage >= threshold
            }
            
            if not results[column]['passed']:
                failed_columns.append(column)
        
        check_result = {
            'check_name': 'value_ranges',
            'column_results': results,
            'failed_columns': failed_columns,
            'overall_passed': len(failed_columns) == 0
        }
        
        self.results['value_ranges'] = check_result
        return check_result
    
    def get_all_results(self) -> Dict[str, Dict[str, Any]]:
        """Return all check results."""
        return self.results
    
    def all_checks_passed(self) -> bool:
        """Return True if all checks passed."""
        for check_name, check_result in self.results.items():
            if not check_result.get('overall_passed', False):
                return False
        return True


# Example usage when run as a script
if __name__ == "__main__":
    from pyspark.sql import SparkSession
    
    # Create Spark session
    spark = SparkSession.builder.appName("DataQualityExample").getOrCreate()
    
    # Create a sample DataFrame
    data = [
        (1, "John", 25, "2021-01-01"),
        (2, "Jane", 30, "2021-02-15"),
        (3, "Bob", None, "2021-03-20"),
        (4, None, 22, None),
        (5, "Alice", 45, "2021-05-10")
    ]
    
    schema = ["id", "name", "age", "date"]
    sample_df = spark.createDataFrame(data, schema)
    
    # Create checker and run checks
    checker = DataQualityChecker(is_spark=True)
    
    # Check for missing values
    checker.check_missing_values(sample_df, threshold=0.3)
    
    # Check uniqueness of ID column
    checker.check_uniqueness(sample_df, ["id"])
    
    # Check age range
    checker.check_value_ranges(sample_df, {
        'age': {'min': 0, 'max': 100, 'threshold': 0.9}
    })
    
    # Get and print results
    results = checker.get_all_results()
    print(f"All checks passed: {checker.all_checks_passed()}")
    
    # Clean up
    spark.stop()