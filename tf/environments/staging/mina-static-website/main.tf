locals {
  bucket_name = "staging-minasearch"
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
    key            = "staging-minasearch/terraform.tfstate"
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
  app_name    = local.app_name
}

output "bucket_endpoint" {
  description = "Bucket endpoint"
  value       = module.mina-static-website.bucket_endpoint
}

output "cloudfront_distribution" {
    description = "CloudFront distribution"
    value       = module.mina-static-website.cloudfront_distribution
}

output "access_key_id" {
    description = "the AWS access key id for the CI/CD user"
    value = module.mina-static-website.access_key_id
}

output "encypted_secret_access_key" {
    description = "Encyrpted AWS secret access key"
    value = module.mina-static-website.encypted_secret_access_key
}