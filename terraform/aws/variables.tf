variable "aws_region" {
  type = string
}
variable "aws_profile" {
  type = string
}

variable "config_file" {
  type    = string
  default = "../../config.json"
}

variable "config_schema" {
  type    = string
  default = "../../config.schema"
}
