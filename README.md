# Granola Terraform

## Bootstrapping Terraform S3 Backend

In order to use the Terraform S3 backend to store terraform state, it
first must be created locally.

```terraform
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
}

provider "aws" {
  region = local.region
}

module "remote_state" {
  source      = "../../../modules/terraform-s3-backend/"
  environment = local.environment
  region      = local.region
}

resource "aws_iam_user" "terraform" {
  name = local.user_name
}

resource "aws_iam_user_policy_attachment" "remote_state_access" {
  user       = aws_iam_user.terraform.name
  policy_arn = module.remote_state.terraform_iam_policy.arn
}
```

Execute the following commands

```bash
terraform init
terraform plan
terraform apply
```

This will provision the required infrastructure for the s3 backend. We
now must update the terraform block to include the following:

```terraform
  backend "s3" {
    bucket         = "granola-tfstate-prod"
    key            = "state/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    kms_key_id     = "alias/state-key-prod"
    dynamodb_table = "granola-tfstate-lock-prod"
  }
```

You must run the `terraform init` command again as we're changing
management of the state file.

You will be asked if you want to copy the current state to the s3
backend. Answer yes and you will be greated with the following
message:

```bash
Terraform has been successfully initialized!
```

# License

Copyright 2023 Granola Systems Inc.
