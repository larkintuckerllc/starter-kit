locals {
  identifier = "starter-kit" # TODO: use [replace]
  region     = "us-east-1" # TODO: use [replace]
}

provider "aws" {
  region = local.region
}

# TODO: UNCOMMENT
/*
provider "kubernetes" { # FOR IMPORT ONLY
  config_context = "arn:aws:eks:us-east-1:143287522423:cluster/starter-kit" # TODO: use [replace]
}
*/

# TODO: COMMENT
provider "kubernetes" { # FOR POST-IMPORT ONLY
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  host                   = data.aws_eks_cluster.this.endpoint
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster" "this" {
  name = local.identifier
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

module "cd" {
  source     = "./modules/cd"
  identifier = local.identifier
  workload   = var.workload
}

module "workloads" {
  source   = "./modules/workloads"
  workload = var.workload
}

/*
module "alb_ingress_controller" {
  k8s_cluster_name = data.aws_eks_cluster.this.name
  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"
  source           = "iplabs/alb-ingress-controller/kubernetes"
  version          = "3.1.0"
}

module "ingress" {
  source          = "./modules/ingress"
  certificate_arn = var.certificate_arn
  webs            = var.webs
  zone_name       = var.zone_name
}
*/
