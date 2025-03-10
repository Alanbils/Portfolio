/*
  AWS Kinesis Streams Module
  
  This module creates Kinesis Data Streams, Kinesis Firehose delivery streams,
  and necessary IAM roles for streaming data ingestion.
*/

locals {
  name_prefix = "kinesis-${var.environment}"
}

# IAM role for Kinesis Firehose
resource "aws_iam_role" "firehose_role" {
  name = "${local.name_prefix}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Policy for Firehose to access S3
resource "aws_iam_policy" "firehose_s3_access" {
  name        = "${local.name_prefix}-firehose-s3-access"
  description = "Policy for Firehose to access S3 data lake"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.data_lake_bucket_arn,
          "${var.data_lake_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_s3_access" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_s3_access.arn
}

# Kinesis Data Streams for different data sources
resource "aws_kinesis_stream" "data_streams" {
  for_each = var.data_streams

  name             = "${local.name_prefix}-${each.key}"
  shard_count      = each.value.shard_count
  retention_period = each.value.retention_period

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "IncomingRecords",
    "OutgoingRecords"
  ]

  stream_mode_details {
    stream_mode = each.value.on_demand_mode ? "ON_DEMAND" : "PROVISIONED"
  }

  encryption_type = "KMS"
  kms_key_id      = var.use_cmk ? var.kms_key_id : "alias/aws/kinesis"

  tags = merge(var.tags, {
    DataSource = each.key
  })
}

# Kinesis Firehose Delivery Streams for each data stream
resource "aws_kinesis_firehose_delivery_stream" "s3_delivery_streams" {
  for_each = aws_kinesis_stream.data_streams

  name        = "${each.value.name}-s3-delivery"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = each.value.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = var.data_lake_bucket_arn
    prefix             = "raw/${each.key}/year=!{timestamp:YYYY}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/${each.key}/!{firehose:error-output-type}/year=!{timestamp:YYYY}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    buffer_size        = var.firehose_buffer_size
    buffer_interval    = var.firehose_buffer_interval

    # Compression and format conversion
    compression_format = "GZIP"
    
    # Enable Parquet conversion for analytics-ready data
    dynamic "data_format_conversion_configuration" {
      for_each = var.enable_data_format_conversion ? [1] : []
      
      content {
        input_format_configuration {
          deserializer {
            json_deserializer {}
          }
        }

        output_format_configuration {
          serializer {
            parquet_serializer {
              compression = "SNAPPY"
            }
          }
        }

        schema_configuration {
          database_name = var.glue_database_name
          role_arn      = aws_iam_role.firehose_role.arn
          table_name    = "${each.key}_table"
          region        = var.region
        }
      }
    }

    # Process data with Lambda before delivering to S3
    dynamic "processing_configuration" {
      for_each = var.enable_processing ? [1] : []
      
      content {
        enabled = true

        processors {
          type = "Lambda"

          parameters {
            parameter_name  = "LambdaArn"
            parameter_value = var.processing_lambda_arn
          }
          
          parameters {
            parameter_name  = "BufferSizeInMBs"
            parameter_value = "3"
          }
          
          parameters {
            parameter_name  = "BufferIntervalInSeconds"
            parameter_value = "60"
          }
        }
      }
    }
  }

  tags = merge(var.tags, {
    DataSource = each.key
  })
}

# CloudWatch Log Group for Kinesis Streams metrics
resource "aws_cloudwatch_log_group" "kinesis_logs" {
  name              = "/aws/kinesis/${local.name_prefix}-streams"
  retention_in_days = var.log_retention_days

  tags = var.tags
}