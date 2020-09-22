locals {
  config_map_common    = <<EOF
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
  name                 = "workload"
  platform_dockerfile = {
    go     = <<EOF
          FROM golang:1.14
          WORKDIR /go/src/app
          COPY . .
          RUN go get -d -v ./...
          RUN go install -v ./...
          EXPOSE 8080
          USER 1000:1000
          ENV PORT=8080
          CMD ["app"]
    EOF
    nodejs = <<EOF
          FROM node:12.18.2
          WORKDIR /usr/src/app
          COPY package*.json ./
          RUN npm install
          COPY . .
          EXPOSE 8080
          USER 1000:1000
          ENV PORT=8080
          CMD [ "npm", "start" ]
    EOF
  }
  platform_version = {
    go     = "$(cat VERSION)"
    nodejs = "$(node -p \"require('./package.json').version\")"
  }
}

data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

# CODEPIPELINE BUCKET
# WHEN DESTORYING WILL FAIL BECAUSE BUCKET IS NOT EMPTY; EMPTY AND RETRY

resource "aws_s3_bucket" "this" {
  bucket = "${var.identifier}-codepipeline-${data.aws_region.this.name}"
  tags = {
    Infrastructure = var.identifier
  }
}

# FOR EACH WORKLOAD RESOURCES

# CODECOMMIT

resource "aws_codecommit_repository" "this" {
  for_each = var.workload
  repository_name = "${var.identifier}-${each.key}"
  tags = {
    Infrastructure = var.identifier
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

# CODEBUILD AWS AUTH CONFIGMAP (MUST BE IMPORTED)

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

# CODEBUILD K8S RBAC

resource "kubernetes_role" "this" {
  for_each = var.workload
  metadata {
    name = "${each.key}-codebuild"
    labels = {
      "app.kubernetes.io/instance" = each.key
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/version"  = var.sk_version
    }
  }
  rule {
    api_groups     = ["apps"]
    resources      = ["deployments"]
    resource_names = [each.key]
    verbs          = ["get","patch", "update"]
  }
}

resource "kubernetes_role_binding" "this" {
  for_each = var.workload
  metadata {
    name = "${each.key}-codebuild"
    labels = {
      "app.kubernetes.io/instance" = each.key
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/version"  = var.sk_version
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${each.key}-codebuild"
  }
  subject {
    kind      = "User"
    name      = aws_iam_role.codebuild[each.key].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# CODEBUILD PROJECT

resource "aws_codebuild_project" "this" {
  for_each = var.workload
  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"] 
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:4.0"
    privileged_mode = true
    type            = "LINUX_CONTAINER"
    environment_variable {
      name  = "DOCKERHUB_PASSWORD"
      type  = "PARAMETER_STORE"
      value = "dockerhub_password"
    }
    environment_variable {
      name  = "DOCKERHUB_USERNAME"
      type  = "PARAMETER_STORE"
      value = "dockerhub_username"
    }
  }
  name         = "${var.identifier}-${each.key}"
  service_role = aws_iam_role.codebuild[each.key].arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  source {
    buildspec  = <<EOF
version: 0.2
phases:
  pre_build:
    commands:
      - export VERSION=${local.platform_version[each.value["platform"]]}
      - |
          cat <<EOT > .dockerignore
          .dockerignore
          .git
          .gitignore
          Dockerfile
          EOT
      - |
          cat <<EOT > Dockerfile
${local.platform_dockerfile[each.value["platform"]]}          EOT
  build:
    commands:
      - echo $DOCKERHUB_PASSWORD | docker login --username $DOCKERHUB_USERNAME --password-stdin
      - docker build -t image:latest .
      - docker tag image:latest ${aws_ecr_repository.this[each.key].repository_url}:$VERSION
  post_build:
    commands:
      - $(aws ecr get-login --no-include-email --region ${data.aws_region.this.name})
      - docker push ${aws_ecr_repository.this[each.key].repository_url}:$VERSION
      - aws eks --region ${data.aws_region.this.name} update-kubeconfig --name ${var.identifier}
      - kubectl set image deployment/${each.key} ${local.name}=${aws_ecr_repository.this[each.key].repository_url}:$VERSION
    EOF
    location   = aws_codecommit_repository.this[each.key].clone_url_http
    type       = "CODECOMMIT"
  }
  tags = {
    Infrastructure = var.identifier
  }
}

# CODEPIPELINE ROLE

resource "aws_iam_role" "codepipeline" {
  for_each = var.workload
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  EOF
  name               = "${var.identifier}-${data.aws_region.this.name}-${each.key}-codepipeline"
  tags = {
    Infrastructure = var.identifier
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  for_each = var.workload
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "${aws_codecommit_repository.this[each.key].arn}",
            "Effect": "Allow"
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
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": "${aws_codebuild_project.this[each.key].arn}",
            "Effect": "Allow"
        }
    ]
}
  EOF
  role = aws_iam_role.codepipeline[each.key].name
}

# CODEPIPELINE PIPELINE

resource "aws_codepipeline" "this" {
  for_each = var.workload
  artifact_store {
    location = aws_s3_bucket.this.bucket
    type     = "S3"
  }
  name     = "${var.identifier}-${each.key}"
  role_arn = aws_iam_role.codepipeline[each.key].arn
  stage {
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        RepositoryName = "${var.identifier}-${each.key}"
        BranchName     = "master"
      }
    }
    name = "Source"
  }
  stage {
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      version          = "1"
      configuration = {
        ProjectName = "${var.identifier}-${each.key}"
      }
    }
    name = "Build"
  }
  tags = {
    Infrastructure = var.identifier
  } 
}
