provider "aws" {
  region = var.region
}

# S3 Data Lake Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project_prefix}-${var.environment}-data-lake"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = var.bucket_versioning ? "Enabled" : "Disabled"
  }
}

# Glue Catalog Database
resource "aws_glue_catalog_database" "data_catalog" {
  name = "${var.project_prefix}_${var.environment}_catalog"
}

# Athena Workgroup
resource "aws_athena_workgroup" "analytics" {
  name = "${var.project_prefix}-${var.environment}-analytics"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.data_lake.bucket}/athena-results/"
      
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = var.tags
}

# Glue Crawlers IAM Role
resource "aws_iam_role" "glue_crawler" {
  name = "${var.project_prefix}-${var.environment}-glue-crawler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach required policies for Glue Crawler
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "s3_access" {
  name = "${var.project_prefix}-${var.environment}-s3-access"
  role = aws_iam_role.glue_crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      }
    ]
  })
}

# Optional KMS encryption
resource "aws_kms_key" "data_lake" {
  count                   = var.enable_encryption ? 1 : 0
  description             = "KMS key for data lake encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                   = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.data_lake[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.data_lake.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}
