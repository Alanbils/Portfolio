resource "aws_cloudwatch_metric_alarm" "data_quality_failures" {
  alarm_name          = "data-quality-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedTests"
  namespace           = "DataQuality"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors data quality test failures"
  alarm_actions      = [aws_sns_topic.data_quality_alerts.arn]

  dimensions = {
    Pipeline = "Production"
  }
}

resource "aws_cloudwatch_metric_alarm" "data_freshness" {
  alarm_name          = "data-freshness-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StaleData"
  namespace           = "DataQuality"
  period             = "3600"
  statistic          = "Maximum"
  threshold          = "0"
  alarm_description  = "This metric monitors for stale data in the warehouse"
  alarm_actions      = [aws_sns_topic.data_quality_alerts.arn]

  dimensions = {
    Pipeline = "Production"
  }
}

resource "aws_sns_topic" "data_quality_alerts" {
  name = "data-quality-alerts"
}

resource "aws_sns_topic_subscription" "data_quality_email" {
  topic_arn = aws_sns_topic.data_quality_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_dashboard" "data_quality" {
  dashboard_name = "data-quality-monitoring"
  dashboard_body = file("${path.module}/../dashboards/data_quality_dashboard.json")
}
