locals {
  user_name   = "terraformuser"
  bucket_name = "staging-mina-static-website"
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
  backend "s3" {
    bucket         = "granola-tfstate-prod"
    key            = "mina-static-website/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    kms_key_id     = "alias/state-key-prod"
    dynamodb_table = "granola-tfstate-lock-prod"
  }
}

provider "aws" {
  region = local.region
}

module "mina-static-website" {
  source      = "../../../modules/s3-static-website/"
  bucket_name = local.bucket_name
}

output "output" {
  value = module.mina-static-website
}
