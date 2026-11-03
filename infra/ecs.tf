data "aws_ecr_repository" "app" {
  name = "wishifai-${var.candidate_id}"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/wishifai-${var.candidate_id}"
  retention_in_days = 7
}

resource "aws_ecs_express_gateway_service" "app" {
  service_name            = "wishifai-${var.candidate_id}"
  execution_role_arn      = "arn:aws:iam::244530008913:role/ecsTaskExecutionRole"
  infrastructure_role_arn = "arn:aws:iam::244530008913:role/service-role/ecsInfrastructureRoleForExpressServices"
  task_role_arn           = aws_iam_role.task.arn
  health_check_path       = "/api/health"

  primary_container {
    image          = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"
    container_port = 8080

    aws_logs_configuration {
      log_group         = aws_cloudwatch_log_group.app.name
      log_stream_prefix = "ecs"
    }

    environment {
      name  = "AWS_REGION"
      value = var.region
    }

    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.uploads.bucket
    }
  }

  depends_on = [aws_iam_role_policy.task]
}