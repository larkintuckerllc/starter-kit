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

# CODEPIPELINE BUCKET

resource "aws_s3_bucket" "this" {
  bucket = "${var.identifier}-codepipeline-${data.aws_region.this.name}"
  tags = {
    Project = var.identifier
  }
}

# FOR EACH WORKLOAD RESOURCES

# CODECOMMIT

resource "aws_codecommit_repository" "this" {
  for_each = var.workload
  repository_name = "${var.identifier}-${each.key}"
  tags = {
    Project = var.identifier
  }
}

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

resource "aws_iam_role_policy" "codebuild" {
  for_each = var.workload
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "eks:DescribeCluster",
            "Resource": "${var.cluster_arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "arn:aws:kms:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:key/*"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameters",
            "Resource": "arn:aws:ssm:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:parameter/dockerhub_username"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameters",
            "Resource": "arn:aws:ssm:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:parameter/dockerhub_password"
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:log-group:/aws/codebuild/${var.identifier}-${each.key}",
                "arn:aws:logs:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:log-group:/aws/codebuild/${var.identifier}-${each.key}:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.this.arn}",
                "${aws_s3_bucket.this.arn}/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_codecommit_repository.this[each.key].arn}"
            ],
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:report-group/${var.identifier}-${each.key}-*"
            ]
        },
        {
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            ],
            "Resource": "${aws_ecr_repository.this[each.key].arn}",
            "Effect": "Allow"
        }
    ]
}
  EOF
  role = aws_iam_role.codebuild[each.key].name
}

#  AWS AUTH CONFIGMAP FOR CODEBUILD (MUST BE IMPORTED)

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
