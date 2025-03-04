/**
* # AWS VPC Module
*
* This module creates a secure VPC infrastructure with the following components:
* - VPC with configurable CIDR block
* - Public and private subnets across multiple AZs
* - NAT Gateways for private subnet internet access
* - Internet Gateway for public subnet internet access
* - Route tables for public and private networks
* - VPC Endpoints for secure AWS service access without internet exposure
* - Network ACLs with security-focused rules
* - VPC Flow Logs for monitoring network traffic
*
* ## Security Considerations
* - Network segmentation through public/private subnets
* - Private subnets have no direct internet access
* - VPC Endpoints minimize data exposure to the internet
* - Network ACLs provide additional network security layer
* - Flow logs enable monitoring for unauthorized access attempts
*/

provider "aws" {
# Provider configuration is expected from the root module
}

locals {
az_count             = length(var.availability_zones)
private_subnet_count = length(var.private_subnet_cidrs)
public_subnet_count  = length(var.public_subnet_cidrs)
}

# Create the VPC
resource "aws_vpc" "main" {
cidr_block           = var.vpc_cidr
enable_dns_hostnames = true
enable_dns_support   = true

tags = merge(
    var.tags,
    {
    Name = "${var.name}-vpc"
    }
)
}

# Create Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
vpc_id = aws_vpc.main.id

tags = merge(
    var.tags,
    {
    Name = "${var.name}-igw"
    }
)
}

# Create public subnets
resource "aws_subnet" "public" {
count                   = local.public_subnet_count
vpc_id                  = aws_vpc.main.id
cidr_block              = var.public_subnet_cidrs[count.index]
availability_zone       = element(var.availability_zones, count.index % local.az_count)
map_public_ip_on_launch = true

tags = merge(
    var.tags,
    {
    Name = "${var.name}-public-subnet-${count.index + 1}"
    Tier = "Public"
    }
)
}

# Create private subnets
resource "aws_subnet" "private" {
count                   = local.private_subnet_count
vpc_id                  = aws_vpc.main.id
cidr_block              = var.private_subnet_cidrs[count.index]
availability_zone       = element(var.availability_zones, count.index % local.az_count)
map_public_ip_on_launch = false

tags = merge(
    var.tags,
    {
    Name = "${var.name}-private-subnet-${count.index + 1}"
    Tier = "Private"
    }
)
}

# Create Elastic IPs for NAT Gateways (one per AZ)
resource "aws_eip" "nat" {
count      = var.single_nat_gateway ? 1 : local.az_count
domain     = "vpc"
depends_on = [aws_internet_gateway.main]

tags = merge(
    var.tags,
    {
    Name = "${var.name}-nat-eip-${count.index + 1}"
    }
)
}

# Create NAT Gateways (one per AZ or just one if single_nat_gateway = true)
resource "aws_nat_gateway" "main" {
count         = var.single_nat_gateway ? 1 : local.az_count
allocation_id = aws_eip.nat[count.index].id
subnet_id     = aws_subnet.public[count.index].id
depends_on    = [aws_internet_gateway.main]

tags = merge(
    var.tags,
    {
    Name = "${var.name}-nat-gateway-${count.index + 1}"
    }
)
}

# Create route table for public subnets
resource "aws_route_table" "public" {
vpc_id = aws_vpc.main.id

tags = merge(
    var.tags,
    {
    Name = "${var.name}-public-route-table"
    }
)
}

# Create route to Internet Gateway for public route table
resource "aws_route" "public_internet_gateway" {
route_table_id         = aws_route_table.public.id
destination_cidr_block = "0.0.0.0/0"
gateway_id             = aws_internet_gateway.main.id
}

# Create route tables for private subnets
resource "aws_route_table" "private" {
count  = var.single_nat_gateway ? 1 : local.az_count
vpc_id = aws_vpc.main.id

tags = merge(
    var.tags,
    {
    Name = "${var.name}-private-route-table-${count.index + 1}"
    }
)
}

# Create routes to NAT Gateways for private route tables
resource "aws_route" "private_nat_gateway" {
count                  = var.single_nat_gateway ? 1 : local.az_count
route_table_id         = aws_route_table.private[count.index].id
destination_cidr_block = "0.0.0.0/0"
nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
count          = local.public_subnet_count
subnet_id      = aws_subnet.public[count.index].id
route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
count          = local.private_subnet_count
subnet_id      = aws_subnet.private[count.index].id
route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index % local.az_count].id
}

# Create Network ACL for public subnets
resource "aws_network_acl" "public" {
vpc_id     = aws_vpc.main.id
subnet_ids = aws_subnet.public[*].id

tags = merge(
    var.tags,
    {
    Name = "${var.name}-public-nacl"
    }
)
}

# Create Network ACL for private subnets
resource "aws_network_acl" "private" {
vpc_id     = aws_vpc.main.id
subnet_ids = aws_subnet.private[*].id

tags = merge(
    var.tags,
    {
    Name = "${var.name}-private-nacl"
    }
)
}

# Network ACL Rules for public subnets (inbound)
resource "aws_network_acl_rule" "public_inbound_http" {
network_acl_id = aws_network_acl.public.id
rule_number    = 100
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 80
to_port        = 80
egress         = false
}

resource "aws_network_acl_rule" "public_inbound_https" {
network_acl_id = aws_network_acl.public.id
rule_number    = 110
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 443
to_port        = 443
egress         = false
}

resource "aws_network_acl_rule" "public_inbound_ephemeral" {
network_acl_id = aws_network_acl.public.id
rule_number    = 120
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 1024
to_port        = 65535
egress         = false
}

# Network ACL Rules for public subnets (outbound)
resource "aws_network_acl_rule" "public_outbound_http" {
network_acl_id = aws_network_acl.public.id
rule_number    = 100
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 80
to_port        = 80
egress         = true
}

resource "aws_network_acl_rule" "public_outbound_https" {
network_acl_id = aws_network_acl.public.id
rule_number    = 110
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 443
to_port        = 443
egress         = true
}

resource "aws_network_acl_rule" "public_outbound_ephemeral" {
network_acl_id = aws_network_acl.public.id
rule_number    = 120
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 1024
to_port        = 65535
egress         = true
}

# Network ACL Rules for private subnets (inbound)
resource "aws_network_acl_rule" "private_inbound_vpc" {
network_acl_id = aws_network_acl.private.id
rule_number    = 100
protocol       = -1
rule_action    = "allow"
cidr_block     = var.vpc_cidr
from_port      = 0
to_port        = 0
egress         = false
}

resource "aws_network_acl_rule" "private_inbound_ephemeral" {
network_acl_id = aws_network_acl.private.id
rule_number    = 110
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 1024
to_port        = 65535
egress         = false
}

# Network ACL Rules for private subnets (outbound)
resource "aws_network_acl_rule" "private_outbound_vpc" {
network_acl_id = aws_network_acl.private.id
rule_number    = 100
protocol       = -1
rule_action    = "allow"
cidr_block     = var.vpc_cidr
from_port      = 0
to_port        = 0
egress         = true
}

resource "aws_network_acl_rule" "private_outbound_http" {
network_acl_id = aws_network_acl.private.id
rule_number    = 110
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 80
to_port        = 80
egress         = true
}

resource "aws_network_acl_rule" "private_outbound_https" {
network_acl_id = aws_network_acl.private.id
rule_number    = 120
protocol       = "tcp"
rule_action    = "allow"
cidr_block     = "0.0.0.0/0"
from_port      = 443
to_port        = 443
egress         = true
}

# VPC S3 Endpoint (Gateway type)
resource "aws_vpc_endpoint" "s3" {
count        = var.enable_s3_endpoint ? 1 : 0
vpc_id       = aws_vpc.main.id
service_name = "com.amazonaws.${var.region}.s3"

tags = merge(
    var.tags,
    {
    Name = "${var.name}-s3-endpoint"
    }
)
}

# Associate VPC S3 Endpoint with route tables
resource "aws_vpc_endpoint_route_table_association" "s3_public" {
count           = var.enable_s3_endpoint ? 1 : 0
route_table_id  = aws_route_table.public.id
vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
count           = var.enable_s3_endpoint ? (var.single_nat_gateway ? 1 : local.az_count) : 0
route_table_id  = aws_route_table.private[count.index].id
vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

# VPC DynamoDB Endpoint (Gateway type)
resource "aws_vpc_endpoint" "dynamodb" {
count        = var.enable_dynamodb_endpoint ? 1 : 0
vpc_id       = aws_vpc.main.id
service_name = "com.amazonaws.${var.region}.dynamodb"

tags = merge(
    var.tags,
    {
    Name = "${var.name}-dynamodb-endpoint"
    }
)
}

# Associate VPC DynamoDB Endpoint with route tables
resource "aws_vpc_endpoint_route_table_association" "dynamodb_public" {
count           = var.enable_dynamodb_endpoint ? 1 : 0
route_table_id  = aws_route_table.public.id
vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private" {
count           = var.enable_dynamodb_endpoint ? (var.single_nat_gateway ? 1 : local.az_count) : 0
route_table_id  = aws_route_table.private[count.index].id
vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
count       = var.enable_vpc_endpoints ? 1 : 0
name        = "${var.name}-vpc-endpoint-sg"
description = "Security group for VPC endpoints"
vpc_id      = aws_vpc.main.id

ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTPS traffic from within VPC"
}

egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
}

tags = merge(
    var.tags,
    {
    Name = "${var.name}-vpc-endpoint-sg"
    }
)
}

# Interface VPC endpoints for AWS services (requiring security group)
resource "aws_vpc_endpoint" "interface_endpoints" {
for_each = var.enable_vpc_endpoints ? toset(var.interface_vpc_endpoints) : toset([])

vpc_id              = aws_vpc.main.id
service_name        = "com.amazonaws.${var.region}.${each.value}"
vpc_endpoint_type   = "Interface"
private_dns_enabled = true
subnet_ids          = aws_subnet.private[*].id
security_group_ids  = [aws_security_group.vpc_endpoints[0].id]

tags = merge(
    var.tags,
    {
    Name = "${var.name}-${each.value}-endpoint"
    }
)
}

# VPC Flow Logs for network traffic monitoring and security analysis
resource "aws_flow_log" "vpc_flow_logs" {
count                = var.enable_flow_logs ? 1 : 0
log_destination      = var.flow_logs_destination_arn
log_destination_type = "s3"
traffic_type         = "ALL"
vpc_id               = aws_vpc.main.id

# Using default format with all fields for comprehensive traffic analysis
log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${instance-id} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"

tags = merge(
    var.tags,
    {
    Name = "${var.name}-vpc-flow-logs"
    }
)
}
