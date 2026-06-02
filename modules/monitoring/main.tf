# ---------------------------------------------------------------------------
# SNS topic: the single fan-out point for every alarm. Email + PagerDuty/Slack
# subscriptions are created only when an endpoint is supplied.
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name = "${var.name_prefix}-db-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_sns_topic_subscription" "pagerduty" {
  count                  = var.pagerduty_endpoint == "" ? 0 : 1
  topic_arn              = aws_sns_topic.alarms.arn
  protocol               = "https"
  endpoint               = var.pagerduty_endpoint
  endpoint_auto_confirms = true
}

# ---------------------------------------------------------------------------
# CloudWatch alarms — the signals an on-call DBA actually pages on.
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "oracle_cpu" {
  alarm_name          = "${var.name_prefix}-oracle-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Oracle CPU above 85% for 15 minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = { DBInstanceIdentifier = var.oracle_instance_id }
}

resource "aws_cloudwatch_metric_alarm" "oracle_free_storage" {
  alarm_name          = "${var.name_prefix}-oracle-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2 GiB
  alarm_description   = "Oracle free storage below 2 GiB"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions          = { DBInstanceIdentifier = var.oracle_instance_id }
}

resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  alarm_name          = "${var.name_prefix}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Aurora CPU above 85% for 15 minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = { DBClusterIdentifier = var.aurora_cluster_id }
}

# Replica lag only matters when there is a reader to lag behind.
resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  count               = var.aurora_reader_count > 0 ? 1 : 0
  alarm_name          = "${var.name_prefix}-aurora-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "AuroraReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 1000 # milliseconds
  alarm_description   = "Aurora replica lag above 1s"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions          = { DBClusterIdentifier = var.aurora_cluster_id }
}
