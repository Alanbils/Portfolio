output "kinesis_stream_arns" {
  description = "Map of stream names to ARNs"
  value       = { for name, stream in aws_kinesis_stream.data_streams : name => stream.arn }
}

output "firehose_delivery_stream_arns" {
  description = "Map of stream names to Firehose delivery ARNs"
  value       = { for name, stream in aws_kinesis_firehose_delivery_stream.s3_delivery_streams : name => stream.arn }
}

output "firehose_role_arn" {
  description = "ARN of the IAM role used by Firehose"
  value       = aws_iam_role.firehose_role.arn
}

output "kinesis_stream_names" {
  description = "List of Kinesis Data Stream names"
  value       = [for stream in aws_kinesis_stream.data_streams : stream.name]
}

output "s3_destination_paths" {
  description = "Map of stream names to their S3 destination path prefixes"
  value = { 
    for name, stream in aws_kinesis_firehose_delivery_stream.s3_delivery_streams : 
    name => "${var.data_lake_bucket_arn}/raw/${name}/" 
  }
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for Kinesis"
  value       = aws_cloudwatch_log_group.kinesis_logs.name
}

output "sample_put_record_command" {
  description = "Sample AWS CLI command to put a record to the first Kinesis stream"
  value       = try("aws kinesis put-record --stream-name ${aws_kinesis_stream.data_streams[keys(var.data_streams)[0]].name} --partition-key user1 --data '{\"user_id\":\"user1\",\"event\":\"page_view\",\"timestamp\":\"2023-01-01T12:00:00Z\"}'", "")
}