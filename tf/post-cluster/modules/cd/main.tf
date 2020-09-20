locals {
    config_map_common = <<EOF
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${var.identifier}-node-instance
  username: system:node:{{EC2PrivateDNSName}}
    EOF
  config_map_workloads = join("", [
    for role in aws_iam_role.codebuild:
    <<EOF
- rolearn: ${role.arn}
  username: ${role.name}
    EOF
  ])
}

data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

# CODEBUILD ROLE

resource "aws_iam_role" "codebuild" {
  for_each           = var.workload
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  name               = "${var.identifier}-${data.aws_region.this.name}-${each.key}-codebuild"
  tags = {
    Infrastructure = var.identifier
  }
}

#  AWS AUTH CONFIGMAP (MUST BE IMPORTED)

resource "kubernetes_config_map" "this" {
  data = length(var.workload) == 0 ? {
    mapRoles = local.config_map_common
  } : {
    mapRoles = join("", [
      local.config_map_common,
      local.config_map_workloads
    ])
  }
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

/*
# ECR

resource "aws_ecr_repository" "this" {
  for_each = var.workload
  image_scanning_configuration {
    scan_on_push = true
  }
  name = "${var.identifier}-${each.key}"
  tags = {
    Infrastructure = var.identifier
  }
}
*/
