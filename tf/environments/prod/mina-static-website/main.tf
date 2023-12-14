locals {
  app_name            = "minasearch"
  region              = "us-east-1"
  domain_name         = "minasearch.com"
  environment         = "production"
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
    key            = "prod-minasearch/terraform.tfstate"
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
  source              = "../../../modules/s3-static-website/"
  app_name            = local.app_name
  domain_name         = local.domain_name
  environment         = local.environment
}

output "bucket_endpoint" {
  description = "Bucket endpoint"
  value       = module.mina-static-website.bucket_endpoint
}

output "cloudfront_distribution" {
  description = "CloudFront distribution"
  value       = module.mina-static-website.cloudfront_distribution
}

output "domain_name" {
  description = "Domain name"
  value       = local.domain_name
}