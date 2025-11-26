provider "aws" {
  region  = "us-west-2"
  profile = "urielmayo"
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      project     = "urielmayo-testing"
    }
  }
}

provider "random" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
  backend "s3" {
    bucket  = "urielmayo-terraform-state"
    key     = "staging/state"
    region  = "us-west-2"
    profile = "urielmayo"
    encrypt = true
  }
}
