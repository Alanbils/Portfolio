provider "aws" {
  region = var.region
}

# Kinesis Data Stream
resource "aws_kinesis_stream" "main" {
  name             = "${var.project_prefix}-${var.environment}-stream"
  shard_count      = var.shard_count
  retention_period = var.retention_period

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Lambda Function for Stream Processing
resource "aws_lambda_function" "processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_prefix}-${var.environment}-stream-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "kinesis_processor.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      OUTPUT_BUCKET = var.output_bucket
    }
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.processor.function_name}"
  retention_in_days = 14
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_prefix}-${var.environment}-stream-processor-role"

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
}

# Lambda Permissions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "stream_processing_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${var.output_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Kinesis Firehose for Data Delivery
resource "aws_kinesis_firehose_delivery_stream" "s3_stream" {
  name        = "${var.project_prefix}-${var.environment}-delivery-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.output_bucket_arn
    prefix     = "raw/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    buffer_size        = 64
    buffer_interval    = 60
    compression_format = "GZIP"
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Firehose IAM Role
resource "aws_iam_role" "firehose_role" {
  name = "${var.project_prefix}-${var.environment}-firehose-role"

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
}
