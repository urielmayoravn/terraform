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

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
  }
  backend "s3" {
    bucket  = "urielmayo-terraform-state"
    key     = "test/state"
    region  = "us-west-2"
    profile = "urielmayo"
    encrypt = true
  }
}