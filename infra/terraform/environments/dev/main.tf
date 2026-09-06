terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "disasterkok-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "disasterkok-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source               = "../../modules/vpc"
  project              = var.project
  env                  = var.env
  public_subnet_cidr_b = var.public_subnet_cidr_b
  az_b                 = var.az_b
}

module "security_group" {
  source  = "../../modules/security-group"
  project = var.project
  env     = var.env
  vpc_id  = module.vpc.vpc_id
  my_ip   = var.my_ip
}

module "iam" {
  source        = "../../modules/iam"
  project       = var.project
  env           = var.env
  github_repo   = var.github_repo
  db_secret_arn = module.rds.secret_arn
}

module "ec2" {
  source                = "../../modules/ec2"
  project               = var.project
  env                   = var.env
  subnet_id             = module.vpc.public_subnet_id
  security_group_id     = module.security_group.k3s_sg_id
  instance_profile_name = module.iam.instance_profile_name
  key_name              = var.key_name
  k3s_version           = var.k3s_version
  ecr_registry          = split("/", module.ecr.repository_url)[0]
  aws_region            = var.aws_region
}

module "ecr" {
  source  = "../../modules/ecr"
  project = var.project
  env     = var.env
}

module "rds" {
  source                = "../../modules/rds"
  project               = var.project
  env                   = var.env
  subnet_id             = module.vpc.public_subnet_id
  subnet_id_b           = module.vpc.public_subnet_id_b
  vpc_id                = module.vpc.vpc_id
  ecs_security_group_id = module.security_group.ecs_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
}

module "ecs" {
  source             = "../../modules/ecs"
  project            = var.project
  env                = var.env
  aws_region         = var.aws_region
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  ecr_repository_url = module.ecr.repository_url
  subnet_id          = module.vpc.public_subnet_id
  subnet_id_b        = module.vpc.public_subnet_id_b
  security_group_id  = module.security_group.ecs_sg_id
}
