provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::246402711611:role/AdministratorAccess"
  }
}

module "this" {
  source      = "../../"
  environment = var.environment
  project     = var.project
  webhooks    = var.webhooks
}