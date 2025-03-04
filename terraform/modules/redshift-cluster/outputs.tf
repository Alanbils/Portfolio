output "redshift_cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = aws_redshift_cluster.warehouse.id
}

output "redshift_cluster_endpoint" {
  description = "The connection endpoint for the Redshift cluster"
  value       = aws_redshift_cluster.warehouse.endpoint
}

output "redshift_cluster_dns_name" {
  description = "The DNS name of the Redshift cluster"
  value       = aws_redshift_cluster.warehouse.dns_name
}

output "redshift_cluster_port" {
  description = "The port that the Redshift cluster is listening on"
  value       = aws_redshift_cluster.warehouse.port
}

output "redshift_database_name" {
  description = "The name of the default database in the Redshift cluster"
  value       = aws_redshift_cluster.warehouse.database_name
}

output "redshift_role_arn" {
  description = "The ARN of the IAM role used by the Redshift cluster"
  value       = aws_iam_role.redshift_role.arn
}

output "security_group_id" {
  description = "The ID of the security group for the Redshift cluster"
  value       = aws_security_group.redshift.id
}

output "jdbc_connection_string" {
  description = "JDBC connection string for connecting to the Redshift cluster"
  value       = "jdbc:redshift://${aws_redshift_cluster.warehouse.endpoint}/${aws_redshift_cluster.warehouse.database_name}"
}

output "connection_instructions" {
  description = "Instructions for connecting to the Redshift cluster"
  value       = <<-EOT
    To connect to the Redshift cluster:
    
    1. Using psql client:
       psql -h ${aws_redshift_cluster.warehouse.endpoint} -p ${aws_redshift_cluster.warehouse.port} -d ${aws_redshift_cluster.warehouse.database_name} -U ${var.master_username}
    
    2. Using JDBC:
       ${nonsensitive("jdbc:redshift://${aws_redshift_cluster.warehouse.endpoint}/${aws_redshift_cluster.warehouse.database_name}?user=${var.master_username}&password=<your-password>")}
    
    3. Using the AWS Console:
       https://${var.region}.console.aws.amazon.com/redshiftv2/home?region=${var.region}#cluster-details?cluster=${aws_redshift_cluster.warehouse.id}
  EOT
}

output "sample_copy_command" {
  description = "Sample COPY command for loading data from S3"
  value       = <<-EOT
    -- Example COPY command to load data from S3 data lake
    COPY ${aws_redshift_cluster.warehouse.database_name}.schema.table
    FROM 's3://${split(":", var.data_lake_bucket_arn)[5]}/processed/data/'
    IAM_ROLE '${aws_iam_role.redshift_role.arn}'
    FORMAT AS PARQUET;
  EOT
}