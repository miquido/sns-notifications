variable "environment" {
  type    = string
  default = ""
}

variable "project" {
  type    = string
  default = ""
}

variable "webhooks" {
  type    = list(string)
  default = ["http://example.com/webhook"]
}
