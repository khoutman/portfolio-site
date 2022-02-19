provider "aws" {
  region = "us-east-2"
}

terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = ">= 3.20.0"
    random = "3.1.0"
    null = "3.1.0"
    local = "2.1.0"
    template = ">= 2.1"
    external = ">= 1.2"
  }
  cloud {
    organization = "khoutman"

    workspaces {
      name = "portfolio-site-workflow"
    }
  }
}
