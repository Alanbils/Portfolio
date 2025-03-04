/*
  AWS Redshift Cluster Module
  
  This module sets up a Redshift cluster with appropriate IAM roles, security groups, 
  subnet groups, and parameter groups for data warehousing.
*/

locals {
  name_prefix = "redshift-${var.environment}"
}

data "aws_caller_identity" "current" {}

# Security group for Redshift cluster
resource "aws_security_group" "redshift" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for Redshift cluster"
  vpc_id      = var.vpc_id

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = var.tags
}

# Ingress rule for client access (should be restricted in production)
resource "aws_security_group_rule" "redshift_client_access" {
  type              = "ingress"
  from_port         = 5439
  to_port           = 5439
  protocol          = "tcp"
  cidr_blocks       = var.is_production ? var.allowed_cidr_blocks : ["0.0.0.0/0"]
  security_group_id = aws_security_group.redshift.id
}

# IAM role for Redshift
resource "aws_iam_role" "redshift_role" {
  name = "${local.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach S3 read policy for COPY commands
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Custom policy for Redshift to access specific data lake paths
resource "aws_iam_policy" "redshift_s3_access" {
  name        = "${local.name_prefix}-s3-access"
  description = "Policy for Redshift to access data lake"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
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

resource "aws_iam_role_policy_attachment" "redshift_s3_access" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_s3_access.arn
}

# Redshift subnet group
resource "aws_redshift_subnet_group" "redshift" {
  name        = "${local.name_prefix}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Redshift subnet group for ${var.environment}"

  tags = var.tags
}

# Redshift parameter group
resource "aws_redshift_parameter_group" "redshift" {
  name        = "${local.name_prefix}-params"
  family      = "redshift-1.0"
  description = "Redshift parameter group for ${var.environment}"

  # Enable logging
  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  # Enhanced VPC routing (use VPC networking for COPY/UNLOAD)
  parameter {
    name  = "require_ssl"
    value = "true"
  }

  tags = var.tags
}

# KMS key for Redshift encryption (if using CMK)
resource "aws_kms_key" "redshift" {
  count = var.use_cmk ? 1 : 0
  
  description             = "KMS key for Redshift cluster in ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  tags = var.tags
}

resource "aws_kms_alias" "redshift" {
  count = var.use_cmk ? 1 : 0
  
  name          = "alias/${local.name_prefix}-key"
  target_key_id = aws_kms_key.redshift[0].key_id
}

# Redshift cluster
resource "aws_redshift_cluster" "warehouse" {
  cluster_identifier        = "${local.name_prefix}-cluster"
  database_name             = var.database_name
  master_username           = var.master_username
  master_password           = var.master_password
  node_type                 = var.node_type
  cluster_type              = var.node_count > 1 ? "multi-node" : "single-node"
  number_of_nodes           = var.node_count > 1 ? var.node_count : null
  
  # Networking
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]
  publicly_accessible       = var.publicly_accessible
  
  # IAM roles
  iam_roles                 = [aws_iam_role.redshift_role.arn]
  
  # Configuration
  cluster_parameter_group_name = aws_redshift_parameter_group.redshift.name
  enhanced_vpc_routing         = true
  
  # Encryption
  encrypted                 = true
  kms_key_id                = var.use_cmk ? aws_kms_key.redshift[0].arn : null
  
  # Availability & Backups
  availability_zone         = var.availability_zone
  automated_snapshot_retention_period = var.is_production ? 35 : 7
  
  # Data sharing
  snapshot_copy {
    destination_region = var.snapshot_copy_region
    retention_period   = var.is_production ? 7 : 1
  }
  
  # Production safeguards
  skip_final_snapshot       = !var.is_production
  final_snapshot_identifier = "${local.name_prefix}-final-snapshot-${formatdate("YYYYMMDD", timestamp())}"
  deletion_protection       = var.is_production
  
  # Maintenance
  maintenance_track_name    = "current"
  automated_snapshot_retention_period = var.snapshot_retention_days
  preferred_maintenance_window = "sun:03:00-sun:05:00"
  
  # Logging and monitoring
  logging {
    enable        = true
    bucket_name   = var.log_bucket_name
    s3_key_prefix = "redshift-logs/${var.environment}"
  }
  
  tags = var.tags
  
  # Prevent recreation when changing master password
  lifecycle {
    ignore_changes = [master_password]
  }
}

# CloudWatch alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "redshift_cpu_utilization" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "This alarm monitors Redshift cluster CPU utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.warehouse.cluster_identifier
  }
  
  tags = var.tags
}