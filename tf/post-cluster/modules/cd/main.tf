data "aws_region" "this" {}

resource "aws_iam_role" "codebuild" {
  for_each           = var.workloads
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
