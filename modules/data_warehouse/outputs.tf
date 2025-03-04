output "redshift_cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = aws_redshift_cluster.main.id
}

output "redshift_cluster_endpoint" {
  description = "The connection endpoint of the Redshift cluster"
  value       = aws_redshift_cluster.main.endpoint
}

output "redshift_cluster_arn" {
  description = "The ARN of the Redshift cluster"
  value       = aws_redshift_cluster.main.arn
}

output "redshift_database_name" {
  description = "The name of the default database in the Redshift cluster"
  value       = aws_redshift_cluster.main.database_name
}

output "redshift_security_group_id" {
  description = "The ID of the security group for the Redshift cluster"
  value       = aws_security_group.redshift.id
}

output "redshift_role_arn" {
  description = "The ARN of the IAM role for the Redshift cluster"
  value       = aws_iam_role.redshift_role.arn
}

output "redshift_kms_key_id" {
  description = "The ID of the KMS key used for Redshift encryption"
  value       = aws_kms_key.redshift.key_id
}

output "redshift_kms_key_arn" {
  description = "The ARN of the KMS key used for Redshift encryption"
  value       = aws_kms_key.redshift.arn
}