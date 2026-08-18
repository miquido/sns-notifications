module "default_formatter" {
  source = "git::https://github.com/miquido/terraform-default-sns-formatter.git?ref=tags/v1.1.0"

  environment = var.environment
  project     = var.project
  formatters  = var.default_message_formatters
}
