output "vpc_id" {
description = "ID of the VPC"
value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
description = "CIDR block of the VPC"
value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
description = "IDs of the public subnets"
value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
description = "IDs of the private subnets"
value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
description = "ID of the public route table"
value       = aws_route_table.public.id
}

output "private_route_table_ids" {
description = "IDs of the private route tables"
value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
description = "IDs of the NAT Gateways"
value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
description = "ID of the Internet Gateway"
value       = aws_internet_gateway.main.id
}

output "vpc_endpoint_s3_id" {
description = "ID of the S3 VPC endpoint"
value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_dynamodb_id" {
description = "ID of the DynamoDB VPC endpoint"
value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "vpc_endpoint_ids" {
description = "Map of interface VPC endpoints created"
value       = var.enable_vpc_endpoints ? { for k, v in aws_vpc_endpoint.interface_endpoints : k => v.id } : {}
}

output "vpc_endpoints_security_group_id" {
description = "ID of the security group used for VPC endpoints"
value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "availability_zones" {
description = "List of availability zones used"
value       = var.availability_zones
}

output "vpc_flow_log_id" {
description = "ID of the VPC Flow Log"
value       = var.enable_flow_logs ? aws_flow_log.vpc_flow_logs[0].id : null
}

output "public_network_acl_id" {
description = "ID of the public network ACL"
value       = aws_network_acl.public.id
}

output "private_network_acl_id" {
description = "ID of the private network ACL"
value       = aws_network_acl.private.id
}

output "nat_public_ips" {
description = "Public IP addresses of the NAT Gateways"
value       = aws_eip.nat[*].public_ip
}

