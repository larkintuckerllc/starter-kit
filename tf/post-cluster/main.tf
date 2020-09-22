locals {
  sk_version = "0.2.0"
}

provider "aws" {
  region = var.REGION
}

provider "kubernetes" { # FOR IMPORT ONLY
  config_context = "[replace]" # arn:aws:eks:[obmitted]:[obmitted]:cluster/[obmitted]
}

/*
provider "kubernetes" { # FOR POST-IMPORT ONLY
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  host                   = data.aws_eks_cluster.this.endpoint
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}
*/

data "aws_eks_cluster" "this" {
  name = var.IDENTIFIER
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

module "workloads" {
  source   = "./modules/workloads"
  sk_version  = local.sk_version
  workload = var.workload
}

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
  sk_version      = local.sk_version
  workload        = var.workload
  zone_name       = var.zone_name
}

module "cd" {
  source      = "./modules/cd"
  cluster_arn = data.aws_eks_cluster.this.arn
  identifier  = var.IDENTIFIER
  sk_version  = local.sk_version
  workload    = var.workload
}
