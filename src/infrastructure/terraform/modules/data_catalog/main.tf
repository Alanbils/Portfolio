provider "aws" {
  region = var.region
}

resource "aws_glue_catalog_database" "data_catalog" {
  name        = "${var.environment}-${var.database_name}"
  description = "Glue catalog database for ${var.environment} environment"
}

resource "aws_glue_crawler" "data_lake_crawler" {
  name          = "${var.environment}-${var.crawler_name}"
  role          = aws_iam_role.glue_service_role.arn
  database_name = aws_glue_catalog_database.data_catalog.name

  s3_target {
    path = "s3://${var.data_lake_bucket}/raw/"
  }

  schedule     = var.crawler_schedule
  table_prefix = var.table_prefix

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  tags = var.tags
}

resource "aws_iam_role" "glue_service_role" {
  name = "${var.environment}-glue-service-role"

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

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access"
  role = aws_iam_role.glue_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.data_lake_bucket}",
          "arn:aws:s3:::${var.data_lake_bucket}/*"
        ]
      }
    ]
  })
}