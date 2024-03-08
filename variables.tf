variable "tags" {
  type        = map(string)
  description = "Default tags to apply on all created resources"
  default     = {}
}

variable "environment" {
  description = "Environment name"
}

variable "project" {
  description = "Project name"
}

variable "log_retention" {
  type    = number
  default = 7
  description = "How long to keep logs"
}

variable "webhooks" {
  type = list(string)
  description = "List of webhooks to call when SNS message is received"
  default = []
}