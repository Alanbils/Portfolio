provider "aws" {
  region = var.region
}

# S3 Data Lake Buckets
resource "aws_s3_bucket" "data_lake" {
  for_each = toset(["raw", "processed", "curated"])
  
  bucket = "${var.project_prefix}-${var.environment}-${each.key}"
  
  tags = merge(var.tags, {
    Layer = each.key
    Environment = var.environment
  })
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = aws_s3_bucket.data_lake
  
  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policies for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = aws_s3_bucket.data_lake
  
  bucket = each.value.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

# AWS Glue Catalog Database
resource "aws_glue_catalog_database" "data_catalog" {
  name = "${var.project_prefix}_${var.environment}_catalog"
}

# AWS Glue Crawler for data discovery
resource "aws_glue_crawler" "data_crawler" {
  for_each = aws_s3_bucket.data_lake

  database_name = aws_glue_catalog_database.data_catalog.name
  name          = "${var.project_prefix}-${var.environment}-${each.key}-crawler"
  role          = aws_iam_role.glue_crawler.arn

  s3_target {
    path = "s3://${each.value.id}"
  }

  schedule = "cron(0 */12 * * ? *)"  # Run every 12 hours
}

# IAM Role for Glue Crawler
resource "aws_iam_role" "glue_crawler" {
  name = "${var.project_prefix}-${var.environment}-glue-crawler-role"

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
}

# Attach necessary policies to Glue Crawler role
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access"
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
        Resource = concat(
          [for bucket in aws_s3_bucket.data_lake : bucket.arn],
          [for bucket in aws_s3_bucket.data_lake : "${bucket.arn}/*"]
        )
      }
    ]
  })
}
