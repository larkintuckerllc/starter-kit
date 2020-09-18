locals {
  az_0       = "us-east-1a" # TODO: use [replace]
  az_1       = "us-east-1b" # TODO: use [replace]
  identifier = "starter-kit" # TODO: use [replace]
  region     = "us-east-1" # TODO: use [replace]
}

provider "aws" {
  region = local.region
}
