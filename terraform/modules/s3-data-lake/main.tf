/*
  S3 Data Lake Terraform Module
  
  This module creates an S3-based data lake with appropriate bucket policies, 
  lifecycle configurations, and access points.
*/

locals {
  bucket_name = "data-lake-${var.environment}-${data.aws_caller_identity.current.account_id}-${var.region}"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "data_lake" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = var.is_production
  }
}

resource "aws_s3_bucket_versioning" "data_lake_versioning" {
  bucket = aws_s3_bucket.data_lake.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake_encryption" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake_lifecycle" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "transition-to-intelligent-tiering"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }

    dynamic "transition" {
      for_each = var.is_production ? [1] : []
      content {
        days          = 90
        storage_class = "GLACIER"
      }
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

# Create different prefixes for the data lake zones
resource "aws_s3_object" "data_lake_zones" {
  for_each = toset(["raw/", "processed/", "curated/", "analytics/"])

  bucket  = aws_s3_bucket.data_lake.id
  key     = each.key
  content = ""
}

# Bucket policy to enforce encryption in transit
resource "aws_s3_bucket_policy" "data_lake_policy" {
  bucket = aws_s3_bucket.data_lake.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnEncryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.data_lake.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.data_lake.arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Create S3 access point for the analytics zone
resource "aws_s3_access_point" "analytics_access_point" {
  bucket = aws_s3_bucket.data_lake.id
  name   = "analytics-access-point"

  # Access point policy to restrict access to analytics zone only
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AnalyticsRole"
        }
        Action    = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource  = [
          "${aws_s3_bucket.data_lake.arn}",
          "${aws_s3_bucket.data_lake.arn}/analytics/*"
        ]
      }
    ]
  })
}