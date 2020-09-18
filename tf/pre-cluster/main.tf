locals {
  availability_zones = [
    "us-east-1a", # TODO: use [replace]
    "us-east-1b" # TODO: use [replace]
  ]
  identifier          = "starter-kit" # TODO: use [replace]
  region              = "us-east-1" # TODO: use [replace]
}

provider "aws" {
  region = local.region
}

module "vpc" {
  source             = "./modules/vpc"
  availability_zones = local.availability_zones
  identifier         = local.identifier
}

output "debug1" {
  value = module.vpc.subnet_ids
}

output "debug2" {
  value = module.vpc.private_subnet_ids
}
