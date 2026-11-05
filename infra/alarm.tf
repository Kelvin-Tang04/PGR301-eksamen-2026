resource "aws_sns_topic" "alarms" {
  name = "${var.metric_namespace}-alarm-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "bedrock_latency" {
  alarm_name        = "${var.metric_namespace}-bedrock-latency"
  alarm_description = "Bedrock-kallet tar lengre tid enn ${var.bedrock_latency_threshold_ms} ms"
  namespace         = var.metric_namespace
  metric_name       = "bedrock.suggest_gifts.max"

  dimensions = {
    class     = "no.pgr301.exam.service.BedrockService"
    method    = "suggestGifts"
    exception = "none"
  }

  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.bedrock_latency_threshold_ms
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}