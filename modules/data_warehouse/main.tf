################################################################################
# Security Group
################################################################################

resource "aws_security_group" "redshift" {
  name        = "${var.project_name}-${var.environment}-redshift-sg"
  description = "Security group for Redshift cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow access from within VPC"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redshift-sg"
    }
  )
}

################################################################################
# IAM Role
################################################################################

resource "aws_iam_role" "redshift_role" {
  name = "${var.project_name}-${var.environment}-redshift-role"
  
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

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy" "redshift_s3_access" {
  name = "${var.project_name}-${var.environment}-redshift-s3-access"
  role = aws_iam_role.redshift_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets"
        ]
        Resource = [
          var.data_lake_bucket_arn,
          "${var.data_lake_bucket_arn}/*"
        ]
      }
    ]
  })
}

################################################################################
# Subnet Group
################################################################################

resource "aws_redshift_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-redshift-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redshift-subnet-group"
    }
  )
}

################################################################################
# Parameter Group
################################################################################

resource "aws_redshift_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-redshift-param-group"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = var.environment == "prod" ? "true" : "false"
  }

  parameter {
    name  = "auto_analyze"
    value = "true"
  }

  parameter {
    name  = "statement_timeout"
    value = var.environment == "prod" ? "43200000" : "7200000" # 12 hours for prod, 2 hours for others
  }

  tags = var.tags
}

################################################################################
# KMS Key for Encryption
################################################################################

resource "aws_kms_key" "redshift" {
  description             = "KMS key for Redshift cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redshift-kms-key"
    }
  )
}

resource "aws_kms_alias" "redshift" {
  name          = "alias/${var.project_name}-${var.environment}-redshift-key"
  target_key_id = aws_kms_key.redshift.key_id
}

################################################################################
# Redshift Cluster
################################################################################

resource "aws_redshift_cluster" "main" {
  cluster_identifier           = "${var.project_name}-${var.environment}"
  database_name                = var.database_name
  master_username              = var.master_username
  master_password              = var.master_password
  node_type                    = var.node_type
  cluster_type                 = var.cluster_type
  number_of_nodes              = var.cluster_type == "single-node" ? 1 : var.number_of_nodes
  
  # Networking
  cluster_subnet_group_name    = aws_redshift_subnet_group.main.name
  vpc_security_group_ids       = [aws_security_group.redshift.id]
  publicly_accessible          = false
  
  # Storage
  encrypted                    = true
  kms_key_id                   = aws_kms_key.redshift.arn
  
  # Configuration
  parameter_group_name         = aws_redshift_parameter_group.main.name
  iam_roles                    = [aws_iam_role.redshift_role.arn]
  
  # Backup
  automated_snapshot_retention_period = var.environment == "prod" ? 35 : 7
  
  # Maintenance
  preferred_maintenance_window = "sun:03:00-sun:05:00"
  allow_version_upgrade        = true
  skip_final_snapshot          = var.environment != "prod"
  final_snapshot_identifier    = var.environment == "prod" ? "${var.project_name}-${var.environment}-final-snapshot" : null
  
  # Enhanced VPC routing
  enhanced_vpc_routing         = true
  
  # Logging
  logging {
    enable               = true
    bucket_name          = var.logging_bucket
    s3_key_prefix        = "redshift-logs"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redshift"
    }
  )

  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

################################################################################
# CloudWatch Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "redshift_cpu" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-redshift-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors Redshift cluster CPU utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redshift_disk_space" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-redshift-low-disk-space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "PercentageDiskSpaceUsed"
  namespace           = "AWS/Redshift"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors Redshift cluster disk space"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.main.id
  }

  tags = var.tags
}