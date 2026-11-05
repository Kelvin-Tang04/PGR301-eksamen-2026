resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.metric_namespace

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Business: bilder analysert"
          region = var.region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            [var.metric_namespace, "wishlist.analyses.count"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Business: gaveforslag per analyse"
          region = var.region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            [var.metric_namespace, "wishlist.suggestions.avg"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Applikasjon: tid per kall (ms)"
          region = var.region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            [var.metric_namespace, "bedrock.suggest_gifts.avg", "class", "no.pgr301.exam.service.BedrockService", "method", "suggestGifts", "exception", "none"],
            [var.metric_namespace, "rekognition.detect_labels.avg", "class", "no.pgr301.exam.service.RekognitionService", "method", "detectLabels", "exception", "none"],
            [var.metric_namespace, "s3.upload.avg", "class", "no.pgr301.exam.service.S3Service", "method", "upload", "exception", "none"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Applikasjon: HTTP-latens /api/analyze (ms)"
          region = var.region
          view   = "timeSeries"
          period = 60
          metrics = [
            [{ expression = "SEARCH('{${var.metric_namespace},exception,method,error,uri,outcome,status} MetricName=\"http.server.requests.avg\" uri=\"/api/analyze\"', 'Average', 60)", id = "e1" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Applikasjon: JVM heap brukt (bytes)"
          region = var.region
          view   = "timeSeries"
          period = 60
          metrics = [
            [{ expression = "SEARCH('{${var.metric_namespace},area,id} MetricName=\"jvm.memory.used.value\" area=\"heap\"', 'Average', 60)", id = "e1" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Infrastruktur: ECS CPU og minne (%)"
          region = var.region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_express_gateway_service.app.cluster, "ServiceName", aws_ecs_express_gateway_service.app.service_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_express_gateway_service.app.cluster, "ServiceName", aws_ecs_express_gateway_service.app.service_name]
          ]
        }
      }
    ]
  })
}