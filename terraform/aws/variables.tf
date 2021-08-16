variable "aws_region" {
  type = string
}
variable "aws_profile" {
  type = string
}

variable "name" {
  type    = string
  default = "lobbyboy"
}

variable "config_file" {
  type    = string
  default = "../../config.json"
}

variable "config_schema" {
  type    = string
  default = "../../docs/schema/config"
}
