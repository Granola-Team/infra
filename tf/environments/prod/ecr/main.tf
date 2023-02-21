locals {
  user_name   = "github-cd-user"
  environment = "prod"
  region      = "ca-central-1"
  ecr_name    = "granola-docker-prod"
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
    key            = "ecr/terraform.tfstate"
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
  source      = "../../../modules/ecr/"
  environment = local.environment
  region      = local.region
  ecr_name    = local.ecr_name
}

resource "aws_iam_user" "github_cd" {
  name = local.user_name
}

resource "aws_iam_user_policy_attachment" "remote_ecr_access" {
  user       = aws_iam_user.github_cd.name
  policy_arn = module.remote_state.ecr_iam_policy.arn
}
