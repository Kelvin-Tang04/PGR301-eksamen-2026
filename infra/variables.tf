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