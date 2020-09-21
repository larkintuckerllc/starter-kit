provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "./modules/vpc"
  availability_zones = var.availability_zones
  identifier         = var.identifier
}

module "cluster" {
  source             = "./modules/cluster"
  identifier         = var.identifier
  private_subnet_ids = module.vpc.private_subnet_ids
  subnet_ids         = module.vpc.subnet_ids
  vpc_id             = module.vpc.vpc_id
}
