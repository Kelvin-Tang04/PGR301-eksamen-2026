terraform {
  backend "s3" {
    bucket       = "pgr301-terraform-state"
    key          = "wishifai/6/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}