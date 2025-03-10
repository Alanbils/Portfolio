/*
  AWS Glue Catalog Module
  
  This module creates Glue databases, tables, crawlers, and necessary IAM roles
  to catalog data in the data lake.
*/

locals {
  name_prefix = "glue-catalog-${var.environment}"
}

# IAM role for Glue crawlers
resource "aws_iam_role" "glue_crawler_role" {
  name = "${local.name_prefix}-crawler-role"

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

# Attach AWSGlueServiceRole managed policy
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Policy for S3 access
resource "aws_iam_policy" "glue_s3_access" {
  name        = "${local.name_prefix}-s3-access"
  description = "Policy for Glue to access S3 data lake"

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
          var.data_lake_bucket_arn,
          "${var.data_lake_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_access" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}

# Glue Database for each data zone
resource "aws_glue_catalog_database" "data_lake_databases" {
  for_each = toset(["raw", "processed", "curated", "analytics"])

  name        = "${var.environment}_${each.key}_db"
  description = "Glue catalog database for ${each.key} data in ${var.environment} environment"
}

# Glue crawlers for each data zone
resource "aws_glue_crawler" "data_lake_crawlers" {
  for_each = toset(["raw", "processed", "curated", "analytics"])

  name          = "${local.name_prefix}-${each.key}-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.data_lake_databases[each.key].name
  
  s3_target {
    path = "s3://${var.data_lake_bucket_name}/${each.key}/"
  }

  # Configuration for crawler behavior
  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
    # This setting merges new metadata when processing a source file
    SchemaChangePolicy = {
      UpdateBehavior = "UPDATE_IN_DATABASE"
      DeleteBehavior = "DEPRECATE_IN_DATABASE"
    }
  })

  # Schedule for production environments only
  schedule = var.is_production ? "cron(0 */6 * * ? *)" : null

  tags = merge(var.tags, {
    DataZone = each.key
  })
}

# Create sample Glue table for analytics dashboard data (for demonstration)
resource "aws_glue_catalog_table" "sample_analytics_table" {
  name          = "dashboard_metrics"
  database_name = aws_glue_catalog_database.data_lake_databases["analytics"].name
  
  table_type = "EXTERNAL_TABLE"
  
  parameters = {
    EXTERNAL              = "TRUE"
    "classification"      = "parquet"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${var.data_lake_bucket_name}/analytics/dashboard_metrics/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    
    ser_de_info {
      name                  = "ParquetSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      
      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "timestamp"
      type = "timestamp"
    }
    
    columns {
      name = "user_id"
      type = "string"
    }
    
    columns {
      name = "event_type"
      type = "string"
    }
    
    columns {
      name = "value"
      type = "double"
    }
    
    columns {
      name = "metadata"
      type = "struct<source:string,version:string,session_id:string>"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }
  
  partition_keys {
    name = "month"
    type = "string"
  }
  
  partition_keys {
    name = "day"
    type = "string"
  }
}