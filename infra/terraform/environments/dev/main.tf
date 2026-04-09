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

module "iam" {
  source  = "../../modules/iam"
  project = var.project
  env     = var.env
}

module "ec2" {
  source                = "../../modules/ec2"
  project               = var.project
  env                   = var.env
  subnet_id             = module.vpc.public_subnet_id
  security_group_id     = module.security_group.k3s_sg_id
  instance_profile_name = module.iam.instance_profile_name
  key_name              = var.key_name
}

module "ecr" {
  source = "../../modules/ecr"
  project = var.project
  env = var.env
}
