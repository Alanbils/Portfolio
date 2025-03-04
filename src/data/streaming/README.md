# Data Streaming Components

This directory contains configurations and code for the streaming data pipelines in the data engineering platform.

## Overview

The streaming components handle real-time data processing for:

- User activity events
- Transaction data
- Sensor and IoT device data
- System and application logs

## Architecture

The streaming pipeline implements a Lambda Architecture with:

1. **Speed Layer**: Processes data in real-time using AWS Kinesis and Kinesis Analytics
2. **Batch Layer**: Periodically processes accumulated data for comprehensive analysis
3. **Serving Layer**: Makes processed data available for querying

## Components

- **kinesis/**: AWS Kinesis Stream and Firehose configurations
- **processors/**: Stream processing code
  - Kinesis Analytics SQL queries
  - KCL consumer applications
- **connectors/**: Destination connectors for processed stream data
  - S3 sink
  - Redshift loader
  - Elasticsearch connector
- **schemas/**: Avro and JSON schema definitions for stream data

## Development

To develop and test streaming components:

1. Configure the streaming environment with appropriate IAM roles and policies
2. Deploy Kinesis streams with the Terraform modules
3. Configure producers to send test data to the streams
4. Develop and test stream processing logic
5. Configure connectors to sink data to the appropriate destinations