variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "candidate_id" {
  type    = string
  default = "6"
}

variable "image_tag" {
  type        = string
  description = "Image tag in ECR (commit SHA) that the service should run"
}

variable "metric_namespace" {
  type    = string
  default = "wishifai-6-l"
}

variable "alarm_email" {
  type = string
}

variable "bedrock_latency_threshold_ms" {
  type    = number
  default = 20000
}