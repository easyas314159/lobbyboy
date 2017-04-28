variable "aws_region" {}
variable "aws_profile" {}

variable "lobbyboy_whitelist" {}
variable "lobbyboy_users" {}
variable "lobbyboy_secrets" {}
variable "lobbyboy_default" {}
variable "lobbyboy_accept_digit" {}

variable "lobbyboy_twilio_sid" {}
variable "lobbyboy_twilio_secret" {}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "aws_caller_identity" "account" {}
