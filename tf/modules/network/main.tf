terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "-> 4.51.0"
    }
  }
  backend "s3" {
    bucket = "mybucket"
    key    = "path/to/my/key"
    region = "us-east-1"
  }
}
provider "aws" {

}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = var.vpm_name
  }
}
