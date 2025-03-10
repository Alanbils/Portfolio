provider "aws" {
  region = var.region
}

# Kinesis Data Stream
resource "aws_kinesis_stream" "data_stream" {
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

# Kinesis Firehose
resource "aws_kinesis_firehose_delivery_stream" "s3_stream" {
  name        = "${var.project_prefix}-${var.environment}-delivery-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.data_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.output_bucket_arn

    prefix              = "raw/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    buffer_size        = 128
    buffer_interval    = 60
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesis/firehose/${var.project_prefix}-${var.environment}-delivery-stream"
      log_stream_name = "S3Delivery"
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = aws_lambda_function.stream_processor.arn
        }
      }
    }
  }

  tags = var.tags
}

# IAM Role for Kinesis Firehose
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

  tags = var.tags
}

# IAM Policy for Kinesis Firehose
resource "aws_iam_role_policy" "firehose_policy" {
  name = "${var.project_prefix}-${var.environment}-firehose-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          var.output_bucket_arn,
          "${var.output_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.data_stream.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = aws_lambda_function.stream_processor.arn
      }
    ]
  })
}

# Lambda Function for Stream Processing
resource "aws_lambda_function" "stream_processor" {
  filename         = "${path.module}/lambda/stream_processor.zip"
  function_name    = "${var.project_prefix}-${var.environment}-stream-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60
  memory_size     = 128

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = var.tags
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_prefix}-${var.environment}-lambda-role"

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

# Attach Lambda basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.stream_processor.function_name}"
  retention_in_days = 14

  tags = var.tags
}
