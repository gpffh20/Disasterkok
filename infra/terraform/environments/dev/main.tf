terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "../../modules/vpc"
  project = var.project
  env     = var.env
}

module "security_group" {
  source  = "../../modules/security-group"
  project = var.project
  env     = var.env
  vpc_id  = module.vpc.vpc_id
  my_ip   = var.my_ip
}
