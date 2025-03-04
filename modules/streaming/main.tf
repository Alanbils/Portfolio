################################################################################
# Kinesis Data Stream
################################################################################

resource "aws_kinesis_stream" "main" {
  name             = var.stream_name
  shard_count      = var.shard_count
  retention_period = var.retention_period

  stream_mode_details {
    stream_mode = var.on_demand_mode ? "ON_DEMAND" : "PROVISIONED"
  }

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.kinesis.id

  tags = merge(
    var.tags,
    {
      Name = var.stream_name
    }
  )
}

################################################################################
# KMS Key for Encryption
################################################################################

resource "aws_kms_key" "kinesis" {
  description             = "KMS key for Kinesis stream encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.stream_name}-kms-key"
    }
  )
}

resource "aws_kms_alias" "kinesis" {
  name          = "alias/${var.stream_name}-key"
  target_key_id = aws_kms_key.kinesis.key_id
}

################################################################################
# IAM Role for Producer
################################################################################

resource "aws_iam_role" "kinesis_producer" {
  name = "${var.project_name}-${var.environment}-kinesis-producer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "kinesis_producer" {
  name        = "${var.project_name}-${var.environment}-kinesis-producer-policy"
  description = "Allows putting records to Kinesis stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:DescribeStream"
        ]
        Effect   = "Allow"
        Resource = aws_kinesis_stream.main.arn
      },
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.kinesis.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kinesis_producer" {
  role       = aws_iam_role.kinesis_producer.name
  policy_arn = aws_iam_policy.kinesis_producer.arn
}

################################################################################
# IAM Role for Consumer
################################################################################

resource "aws_iam_role" "kinesis_consumer" {
  name = "${var.project_name}-${var.environment}-kinesis-consumer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "kinesis_consumer" {
  name        = "${var.project_name}-${var.environment}-kinesis-consumer-policy"
  description = "Allows reading records from Kinesis stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards"
        ]
        Effect   = "Allow"
        Resource = aws_kinesis_stream.main.arn
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.kinesis.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kinesis_consumer" {
  role       = aws_iam_role.kinesis_consumer.name
  policy_arn = aws_iam_policy.kinesis_consumer.arn
}

################################################################################
# CloudWatch Logging
################################################################################

resource "aws_cloudwatch_log_group" "kinesis_logs" {
  name              = "/aws/kinesis/${var.stream_name}"
  retention_in_days = 30

  tags = var.tags
}

################################################################################
# CloudWatch Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "get_records_iterator_age" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.stream_name}-iterator-age-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "43200000" # 12 hours
  alarm_description   = "Alarm when the iterator age exceeds 12 hours"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    StreamName = aws_kinesis_stream.main.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "put_records_throttled" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.stream_name}-put-records-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alarm when write throughput is exceeded"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    StreamName = aws_kinesis_stream.main.name
  }

  tags = var.tags
}

################################################################################
# Kinesis Data Firehose (Optional)
################################################################################

resource "aws_kinesis_firehose_delivery_stream" "s3_delivery" {
  count       = var.enable_firehose_delivery ? 1 : 0
  name        = "${var.stream_name}-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.main.arn
    role_arn           = aws_iam_role.firehose[0].arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose[0].arn
    bucket_arn          = var.data_lake_bucket_arn
    prefix              = "raw/kinesis/${var.stream_name}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    buffer_size         = 128
    buffer_interval     = 300
    compression_format  = "GZIP"
    
    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${var.firehose_processor_lambda_arn}:$LATEST"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose[0].name
      log_stream_name = "S3Delivery"
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "firehose" {
  count             = var.enable_firehose_delivery ? 1 : 0
  name              = "/aws/kinesisfirehose/${var.stream_name}-firehose"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_iam_role" "firehose" {
  count = var.enable_firehose_delivery ? 1 : 0
  name  = "${var.project_name}-${var.environment}-firehose-role"

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

resource "aws_iam_policy" "firehose" {
  count       = var.enable_firehose_delivery ? 1 : 0
  name        = "${var.project_name}-${var.environment}-firehose-policy"
  description = "Allows Firehose to read from Kinesis and write to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
        ]
        Effect   = "Allow"
        Resource = aws_kinesis_stream.main.arn
      },
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          var.data_lake_bucket_arn,
          "${var.data_lake_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Effect   = "Allow"
        Resource = var.firehose_processor_lambda_arn
      },
      {
        Action = [
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.firehose[0].arn
      },
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.kinesis.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose" {
  count      = var.enable_firehose_delivery ? 1 : 0
  role       = aws_iam_role.firehose[0].name
  policy_arn = aws_iam_policy.firehose[0].arn
}