# Security Groups Module - Outputs

output "db_security_group_id" {
description = "The ID of the security group for databases (RDS)"
value       = aws_security_group.database.id
}

output "redshift_security_group_id" {
description = "The ID of the security group for Redshift clusters"
value       = aws_security_group.redshift.id
}

output "lambda_security_group_id" {
description = "The ID of the security group for Lambda functions"
value       = aws_security_group.lambda.id
}

output "glue_security_group_id" {
description = "The ID of the security group for AWS Glue services"
value       = aws_security_group.glue.id
}

output "dms_security_group_id" {
description = "The ID of the security group for AWS DMS instances"
value       = aws_security_group.dms.id
}

output "monitoring_security_group_id" {
description = "The ID of the security group for monitoring services"
value       = aws_security_group.monitoring.id
}

output "app_security_group_id" {
description = "The ID of the security group for application services"
value       = aws_security_group.application.id
}

output "internal_services_security_group_id" {
description = "The ID of the security group for internal services"
value       = aws_security_group.internal_services.id
}

output "security_group_ids" {
description = "Map of all security group IDs created by this module"
value = {
    database         = aws_security_group.database.id
    redshift         = aws_security_group.redshift.id
    lambda           = aws_security_group.lambda.id
    glue             = aws_security_group.glue.id
    dms              = aws_security_group.dms.id
    monitoring       = aws_security_group.monitoring.id
    application      = aws_security_group.application.id
    internal_services = aws_security_group.internal_services.id
}
}

