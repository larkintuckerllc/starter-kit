locals {
  sk_version = "0.2.1"
}

provider "aws" {
  region = var.REGION
}

module "vpc" {
  source             = "./modules/vpc"
  availability_zones = var.AVAILABILITY_ZONES
  identifier         = var.IDENTIFIER
}

module "cluster" {
  source             = "./modules/cluster"
  identifier         = var.IDENTIFIER
  private_subnet_ids = module.vpc.private_subnet_ids
  subnet_ids         = module.vpc.subnet_ids
  vpc_id             = module.vpc.vpc_id
}
