output "data_lake_bucket_id" {
  description = "The ID of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.id
}

output "data_lake_bucket_arn" {
  description = "The ARN of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "data_lake_bucket_domain_name" {
  description = "The domain name of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket_domain_name
}

output "access_logs_bucket_id" {
  description = "The ID of the access logs S3 bucket"
  value       = var.enable_access_logs ? aws_s3_bucket.access_logs[0].id : null
}

output "access_logs_bucket_arn" {
  description = "The ARN of the access logs S3 bucket"
  value       = var.enable_access_logs ? aws_s3_bucket.access_logs[0].arn : null
}