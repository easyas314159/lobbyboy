variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_profile" {
  type    = string
  default = "kevinloney"
}

variable "twilio_secret" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = null
}

variable "voice" {
  type    = string
  default = "man"
}
variable "language" {
  type    = string
  default = "en-US"
}
variable "caller_id" {
  type    = string
  default = null
}

variable "users" {
  type = map
}

variable "delivery" {
  type    = string
  default = null
}

variable "party_code" {
  type    = string
  default = null
}

variable "accept_digits" {
  type    = string
  default = "9"
}
