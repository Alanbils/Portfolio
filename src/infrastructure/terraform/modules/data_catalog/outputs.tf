output "glue_database_name" {
  description = "Name of the AWS Glue catalog database"
  value       = aws_glue_catalog_database.data_catalog.name
}

output "glue_crawler_name" {
  description = "Name of the AWS Glue crawler"
  value       = aws_glue_crawler.data_lake_crawler.name
}

output "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue services"
  value       = aws_iam_role.glue_service_role.arn
}

output "database_arn" {
  description = "ARN of the Glue catalog database"
  value       = aws_glue_catalog_database.data_catalog.arn
}

output "database_id" {
  description = "ID of the Glue catalog database"
  value       = aws_glue_catalog_database.data_catalog.id
}