locals {
  identifier = "starter-kit" # TODO: use [replace]
  region     = "us-east-1" # TODO: use [replace]
}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  # TODO IMPORT
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  host                   = data.aws_eks_cluster.this.endpoint
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_caller_identity" "this" {}

data "aws_eks_cluster" "this" {
  name = local.identifier
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

module "alb_ingress_controller" {
  k8s_cluster_name = data.aws_eks_cluster.this.name
  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"
  source           = "iplabs/alb-ingress-controller/kubernetes"
  version          = "3.1.0"
}

/*
module "ingress" {
  source          = "./modules/ingress"
  certificate_arn = var.certificate_arn
  webs            = var.webs
  zone_name       = var.zone_name
}

module "webs" {
  source = "./modules/webs"
  webs   = var.webs
}

module "cd" {
  source     = "./modules/cd"
  identifier = local.identifier
  webs       = var.webs
}

# IMPORTED CONFIG_MAP

locals {
  roles_block = join("", [
    for role in module.cd.codebuild_role:
    <<EOF
- rolearn: ${role.arn}
  username: ${role.name}
    EOF
  ])
}

resource "kubernetes_config_map" "this" {
  data = {
    mapRoles = <<EOF
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${local.identifier}-NodeInstanceRole
  username: system:node:{{EC2PrivateDNSName}}
${local.roles_block}
EOF
  }
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}
*/