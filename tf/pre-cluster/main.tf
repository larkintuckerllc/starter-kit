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
  availability_zones = local.availability_zones
  identifier         = local.identifier
  source             = "./modules/vpc"
}

output "debug" {
  value = module.vpc.subnet_ids
}
