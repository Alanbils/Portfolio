################################################################################
# S3 Data Lake Bucket
################################################################################

resource "aws_s3_bucket" "data_lake" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

################################################################################
# Data Lake Bucket Policy
################################################################################

resource "aws_s3_bucket_policy" "data_lake_policy" {
  bucket = aws_s3_bucket.data_lake.id
  policy = data.aws_iam_policy_document.data_lake_policy.json
}

data "aws_iam_policy_document" "data_lake_policy" {
  statement {
    sid = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.data_lake.arn,
      "${aws_s3_bucket.data_lake.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

################################################################################
# Data Lake Bucket Versioning
################################################################################

resource "aws_s3_bucket_versioning" "data_lake_versioning" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

################################################################################
# Data Lake Bucket Lifecycle Rules
################################################################################

resource "aws_s3_bucket_lifecycle_configuration" "data_lake_lifecycle" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id = "transition-to-intelligent-tiering"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id = "transition-to-standard-ia"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id = "archive-old-data"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = var.retention_days
    }
  }

  # Only enable for non-production environments
  dynamic "rule" {
    for_each = var.environment != "prod" ? [1] : []
    content {
      id = "expire-temp-data"
      status = "Enabled"

      filter {
        prefix = "temp/"
      }

      expiration {
        days = 7
      }
    }
  }
}

################################################################################
# Data Lake Bucket Encryption
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake_encryption" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

################################################################################
# Data Lake Directory Structure
################################################################################

# Create initial folders for the data lake
resource "aws_s3_object" "raw_folder" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "raw/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "processed_folder" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "processed/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "curated_folder" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "curated/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "archive_folder" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "archive/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "temp_folder" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "temp/"
  content_type = "application/x-directory"
}

################################################################################
# Access Logging
################################################################################

resource "aws_s3_bucket" "access_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = "${var.bucket_name}-access-logs"

  tags = merge(
    var.tags,
    {
      Name = "${var.bucket_name}-access-logs"
    }
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs_lifecycle" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    id = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_encryption" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "data_lake_logging" {
  count         = var.enable_access_logs ? 1 : 0
  bucket        = aws_s3_bucket.data_lake.id
  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "s3-logs/"
}