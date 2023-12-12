locals {
  user_name   = "terraformuser"
  environment = "prod"
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
    key            = "state/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    kms_key_id     = "alias/state-key-prod"
    dynamodb_table = "granola-tfstate-lock-prod"
  }
}

provider "aws" {
  region = local.region
}

module "remote_state" {
  source      = "../../../modules/terraform-s3-backend/"
  environment = local.environment
  region      = local.region
}
