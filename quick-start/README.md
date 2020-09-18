# Quick Start

## Prerequisites

- Amazon Web Services (AWS) account; [How do I create and activate a new AWS account?](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)

- Docker Hub Account; [Docker Hub](https://hub.docker.com/)

- AWS Identity Access and Management (IAM) user with administrator access, e.g., has *AdministratorAccess* policy; [Creating your first IAM admin user and group](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html)

- Amazon Route 53 hosted zone; This can be accomplished by registering a new domain; [Step 1: Register a domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html#getting-started-find-domain-name). This also can be accomplished by [Making Amazon Route 53 the DNS service for an existing domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html)

- AWS Certificate Manager public wild card certificate for the domain; [Requesting a Public Certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)

- Workstation with latest Terraform CLI installed; [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

- Workstation with latest AWS CLI configured with the user with administrator access; [Installing the AWS CLI version 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [Configuration basics](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)

- (Recommended) Workstation with Kubernetes CLI, *kubectl*, version 1.17 installed; [Install and Set Up kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Download Terraform Configurations

Two Terraform configurations, *pre-cluster* and *post-cluster*, are provided in the *tf* folder of the downloadable [starter-kit](https://github.com/larkintuckerllc/starter-kit) GitHub repository.

## Update Terraform Configurations' Variables

1. Copy the file *post-cluster/terraform.tfvars.sample* to *post-cluster/terraform.tfvars*

2. Edit the file *post-cluster/terraform.tfvars*

3. Update the value of the *certificate_arn* variable with the public wild card certificate ARN (from prerequisites); for example *arn:aws:acm:[obmitted]:[obmitted]:certificate/[obmitted]*

4. Update the value of the *zone_name* variable with the domain name associated with the host zone (from prerequisites); for example *todosrus.com*

5. Save the file
