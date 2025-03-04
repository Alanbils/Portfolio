# Security Groups Module
# This module creates security groups for various AWS services with secure defaults

terraform {
required_version = ">= 1.0.0"
required_providers {
    aws = {
    source  = "hashicorp/aws"
    version = ">= 4.0.0"
    }
}
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABASE SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

# RDS Security Group
resource "aws_security_group" "rds" {
name        = "${var.namespace}-rds-sg"
description = "Security group for RDS instances"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-rds-sg"
    }
)
}

# We create a separate ingress rule resource to decouple it from the security group
resource "aws_security_group_rule" "rds_ingress" {
for_each = { for idx, cidr in var.allowed_database_cidrs : idx => cidr }

type              = "ingress"
from_port         = var.rds_port
to_port           = var.rds_port
protocol          = "tcp"
cidr_blocks       = [each.value]
security_group_id = aws_security_group.rds.id
description       = "Allow inbound traffic to RDS from specific CIDR blocks"
}

# Allow ingress from application security group if provided
resource "aws_security_group_rule" "rds_app_ingress" {
count                    = length(var.app_security_group_ids) > 0 ? 1 : 0
type                     = "ingress"
from_port                = var.rds_port
to_port                  = var.rds_port
protocol                 = "tcp"
source_security_group_id = var.app_security_group_ids[0]
security_group_id        = aws_security_group.rds.id
description              = "Allow inbound traffic to RDS from application tier"
}

# Block all outbound traffic by default
resource "aws_security_group_rule" "rds_egress" {
type              = "egress"
from_port         = 0
to_port           = 0
protocol          = "-1"
cidr_blocks       = var.restrict_outbound ? [] : ["0.0.0.0/0"]
security_group_id = aws_security_group.rds.id
description       = "Control outbound traffic from RDS"
}

# Redshift Security Group
resource "aws_security_group" "redshift" {
name        = "${var.namespace}-redshift-sg"
description = "Security group for Redshift clusters"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-redshift-sg"
    }
)
}

resource "aws_security_group_rule" "redshift_ingress" {
for_each = { for idx, cidr in var.allowed_database_cidrs : idx => cidr }

type              = "ingress"
from_port         = var.redshift_port
to_port           = var.redshift_port
protocol          = "tcp"
cidr_blocks       = [each.value]
security_group_id = aws_security_group.redshift.id
description       = "Allow inbound traffic to Redshift from specific CIDR blocks"
}

# Allow ingress from application security group if provided
resource "aws_security_group_rule" "redshift_app_ingress" {
count                    = length(var.app_security_group_ids) > 0 ? 1 : 0
type                     = "ingress"
from_port                = var.redshift_port
to_port                  = var.redshift_port
protocol                 = "tcp"
source_security_group_id = var.app_security_group_ids[0]
security_group_id        = aws_security_group.redshift.id
description              = "Allow inbound traffic to Redshift from application tier"
}

# Block all outbound traffic by default
resource "aws_security_group_rule" "redshift_egress" {
type              = "egress"
from_port         = 0
to_port           = 0
protocol          = "-1"
cidr_blocks       = var.restrict_outbound ? [] : ["0.0.0.0/0"]
security_group_id = aws_security_group.redshift.id
description       = "Control outbound traffic from Redshift"
}

# ---------------------------------------------------------------------------------------------------------------------
# APPLICATION SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

# EC2 Application Security Group
resource "aws_security_group" "app" {
name        = "${var.namespace}-app-sg"
description = "Security group for application servers (EC2)"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-app-sg"
    }
)
}

# Allow inbound traffic to application servers
resource "aws_security_group_rule" "app_http_ingress" {
count             = var.allow_app_http ? 1 : 0
type              = "ingress"
from_port         = 80
to_port           = 80
protocol          = "tcp"
cidr_blocks       = var.allowed_app_cidrs
security_group_id = aws_security_group.app.id
description       = "Allow HTTP inbound traffic to application servers"
}

resource "aws_security_group_rule" "app_https_ingress" {
count             = var.allow_app_https ? 1 : 0
type              = "ingress"
from_port         = 443
to_port           = 443
protocol          = "tcp"
cidr_blocks       = var.allowed_app_cidrs
security_group_id = aws_security_group.app.id
description       = "Allow HTTPS inbound traffic to application servers"
}

resource "aws_security_group_rule" "app_ssh_ingress" {
count             = var.allow_app_ssh ? 1 : 0
type              = "ingress"
from_port         = 22
to_port           = 22
protocol          = "tcp"
cidr_blocks       = var.allowed_ssh_cidrs
security_group_id = aws_security_group.app.id
description       = "Allow SSH inbound traffic to application servers from specific IPs"
}

# Allow outbound traffic from application servers
resource "aws_security_group_rule" "app_egress" {
type              = "egress"
from_port         = 0
to_port           = 0
protocol          = "-1"
cidr_blocks       = var.restrict_outbound ? var.allowed_app_egress_cidrs : ["0.0.0.0/0"]
security_group_id = aws_security_group.app.id
description       = "Control outbound traffic from application servers"
}

# Lambda Security Group
resource "aws_security_group" "lambda" {
name        = "${var.namespace}-lambda-sg"
description = "Security group for Lambda functions"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-lambda-sg"
    }
)
}

# Lambda typically needs outbound access to services it interacts with
resource "aws_security_group_rule" "lambda_egress" {
type              = "egress"
from_port         = 0
to_port           = 0
protocol          = "-1"
cidr_blocks       = var.restrict_outbound ? var.allowed_lambda_egress_cidrs : ["0.0.0.0/0"]
security_group_id = aws_security_group.lambda.id
description       = "Control outbound traffic from Lambda functions"
}

# ---------------------------------------------------------------------------------------------------------------------
# INTERNAL SERVICES SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

# DynamoDB Gateway Endpoint Security Group (if VPC endpoints are used)
resource "aws_security_group" "dynamodb_endpoint" {
count       = var.create_dynamodb_endpoint_sg ? 1 : 0
name        = "${var.namespace}-dynamodb-endpoint-sg"
description = "Security group for DynamoDB VPC Endpoint"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-dynamodb-endpoint-sg"
    }
)
}

resource "aws_security_group_rule" "dynamodb_endpoint_ingress" {
count                    = var.create_dynamodb_endpoint_sg ? length(var.internal_security_group_ids) : 0
type                     = "ingress"
from_port                = 443
to_port                  = 443
protocol                 = "tcp"
source_security_group_id = var.internal_security_group_ids[count.index]
security_group_id        = aws_security_group.dynamodb_endpoint[0].id
description              = "Allow HTTPS inbound traffic to DynamoDB VPC Endpoint"
}

# No egress rules needed for VPC endpoints

# Glue Security Group
resource "aws_security_group" "glue" {
name        = "${var.namespace}-glue-sg"
description = "Security group for AWS Glue connections"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-glue-sg"
    }
)
}

# Allow outbound connections from Glue to databases
resource "aws_security_group_rule" "glue_to_rds_egress" {
type                     = "egress"
from_port                = var.rds_port
to_port                  = var.rds_port
protocol                 = "tcp"
source_security_group_id = aws_security_group.rds.id
security_group_id        = aws_security_group.glue.id
description              = "Allow outbound traffic from Glue to RDS"
}

resource "aws_security_group_rule" "glue_to_redshift_egress" {
type                     = "egress"
from_port                = var.redshift_port
to_port                  = var.redshift_port
protocol                 = "tcp"
source_security_group_id = aws_security_group.redshift.id
security_group_id        = aws_security_group.glue.id
description              = "Allow outbound traffic from Glue to Redshift"
}

# Additional egress rules for Glue to reach other services
resource "aws_security_group_rule" "glue_egress" {
type              = "egress"
from_port         = 0
to_port           = 0
protocol          = "-1"
cidr_blocks       = var.restrict_outbound ? var.allowed_glue_egress_cidrs : ["0.0.0.0/0"]
security_group_id = aws_security_group.glue.id
description       = "Control outbound traffic from Glue"
}

# ---------------------------------------------------------------------------------------------------------------------
# MONITORING AND MANAGEMENT SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

# Monitoring Security Group (for CloudWatch agents, etc.)
resource "aws_security_group" "monitoring" {
name        = "${var.namespace}-monitoring-sg"
description = "Security group for monitoring services"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-monitoring-sg"
    }
)
}

# Allow monitoring agents to connect to resources
resource "aws_security_group_rule" "monitoring_egress" {
type              = "egress"
from_port         = 0
to_port           = 0
protocol          = "-1"
cidr_blocks       = var.restrict_outbound ? var.allowed_monitoring_egress_cidrs : ["0.0.0.0/0"]
security_group_id = aws_security_group.monitoring.id
description       = "Allow outbound traffic from monitoring services"
}

# Allow specific monitoring ingress (for health checks, etc.)
resource "aws_security_group_rule" "monitoring_ingress" {
count             = length(var.monitoring_ports) > 0 ? length(var.monitoring_ports) : 0
type              = "ingress"
from_port         = var.monitoring_ports[count.index]
to_port           = var.monitoring_ports[count.index]
protocol          = "tcp"
cidr_blocks       = var.allowed_monitoring_cidrs
security_group_id = aws_security_group.monitoring.id
description       = "Allow inbound traffic to monitoring ports"
}

# Management Security Group (for bastion hosts, etc.)
resource "aws_security_group" "management" {
count       = var.create_management_sg ? 1 : 0
name        = "${var.namespace}-management-sg"
description = "Security group for management resources like bastion hosts"
vpc_id      = var.vpc_id

tags = merge(
    var.tags,
    {
    Name = "${var.namespace}-management-sg"
    }
)
}

resource "aws_security_group_rule" "management_ssh_ingress" {
count             = var.create_management_sg ? 1 : 0
type              = "ingress"
from_port         = 22
to_port           = 22
protocol          = "tcp"
cidr_blocks       = var.allowed_ssh_cidrs
security_group_id = aws_security_group.management[0].id
description       = "Allow SSH inbound traffic to management resources"
}

resource "aws_security_group_rule" "management_egress" {
count             = var.create_management_sg ? 1 : 0
type              = "egress"
from_port         = 0
to_port           = 0
protocol          = "-1"
cidr_blocks       = var.restrict_outbound ? var.allowed_management_egress_cidrs : ["0.0.0.0/0"]
security_group_id = aws_security_group.management[0].id
description       = "Control outbound traffic from management resources"
}

