locals {
  availability_zones = [
    "[replace]", # us-east-1a
    "[replace]"  # us-east-2b
  ]
  identifier          = "[replace]" # starter-kit
  region              = "[replace]"  # us-east-1
}

provider "aws" {
  region = local.region
}

module "vpc" {
  source             = "./modules/vpc"
  availability_zones = local.availability_zones
  identifier         = local.identifier
}

module "cluster" {
  source             = "./modules/cluster"
  identifier         = local.identifier
  private_subnet_ids = module.vpc.private_subnet_ids
  subnet_ids         = module.vpc.subnet_ids
  vpc_id             = module.vpc.vpc_id
}
