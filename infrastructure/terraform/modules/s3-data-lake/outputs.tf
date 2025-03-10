output "data_lake_bucket_id" {
  description = "The ID of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.id
}

output "data_lake_bucket_arn" {
  description = "The ARN of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "data_lake_bucket_name" {
  description = "The name of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "analytics_access_point_arn" {
  description = "The ARN of the analytics access point"
  value       = aws_s3_access_point.analytics_access_point.arn
}

output "data_lake_zones" {
  description = "The configured zones in the data lake"
  value       = [for zone in aws_s3_object.data_lake_zones : zone.key]
}

output "data_lake_domain_name" {
  description = "The domain name of the data lake bucket"
  value       = aws_s3_bucket.data_lake.bucket_domain_name
}

output "data_lake_regional_domain_name" {
  description = "The regional domain name of the data lake bucket"
  value       = aws_s3_bucket.data_lake.bucket_regional_domain_name
}