terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.56.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.8.0"
    }
  }


  cloud {
    organization = "khoutman"

    workspaces {
      name = "portfolio-site-workflow"
    }
  }
}


provider "aws" {
  region = var.region
}

