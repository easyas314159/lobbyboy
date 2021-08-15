terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

data "aws_caller_identity" "this" {}
