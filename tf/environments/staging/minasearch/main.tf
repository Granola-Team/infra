locals {
  user_name   = "terraformuser"
  bucket_name = "staging-mina-search"
  region      = "ca-central-1"
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = local.region
}

module "remote_state" {
  source      = "../../../modules/minasearch/"
  bucket_name = local.bucket_name
}
