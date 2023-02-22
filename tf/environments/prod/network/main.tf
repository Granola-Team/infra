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
    key            = "mina-node/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    kms_key_id     = "alias/state-key-prod"
    dynamodb_table = "granola-tfstate-lock-prod"
  }
}

locals {
  environment        = "prod"
  region             = "ca-central-1"
  availability_zones = ["ca-central-1a"]
}

provider "aws" {
  region = local.region
}

module "mina-node-network" {
  source                 = "infrablocks/base-networking/aws"
  version                = "4.0.0"

  component              = "granola"
  deployment_identifier  = "prod"
  vpc_cidr               = "10.0.0.0/16"
  public_subnets_offset  = 0 // 10.0.0.0/24
  private_subnets_offset = 1 // 10.0.1.0/24
  region                 = local.region
  availability_zones     = local.availability_zones
}
