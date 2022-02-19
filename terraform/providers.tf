provider "aws" {
  region = "us-east-2"
}

terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = ">= 2.66.0"
    random = ">= 2.2"
    null = ">= 2.1"
    local = ">= 1.4"
    template = ">= 2.1"
    external = ">= 1.2"
  }

  backend "s3" {
    bucket = "kyle-oakley-portfolio"
    encrypt = true
    key = "global-aws-infrastructure/eks"
    region = "us-east-2"
  }
}
