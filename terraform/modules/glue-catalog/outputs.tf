output "database_names" {
  description = "Map of data zone to database names"
  value       = { for zone, db in aws_glue_catalog_database.data_lake_databases : zone => db.name }
}

output "crawler_names" {
  description = "Map of data zone to crawler names"
  value       = { for zone, crawler in aws_glue_crawler.data_lake_crawlers : zone => crawler.name }
}

output "glue_crawler_role_arn" {
  description = "ARN of the IAM role used by Glue crawlers"
  value       = aws_iam_role.glue_crawler_role.arn
}

output "sample_table_name" {
  description = "Name of the sample table created for demonstration"
  value       = aws_glue_catalog_table.sample_analytics_table.name
}

output "sample_table_id" {
  description = "Full ID of the sample Glue table"
  value       = "${aws_glue_catalog_database.data_lake_databases["analytics"].name}.${aws_glue_catalog_table.sample_analytics_table.name}"
}

output "athena_query_example" {
  description = "Example Athena query to query the sample table"
  value       = "SELECT * FROM ${aws_glue_catalog_database.data_lake_databases["analytics"].name}.${aws_glue_catalog_table.sample_analytics_table.name} WHERE year='2023' AND month='01' AND day='01' LIMIT 10;"
}