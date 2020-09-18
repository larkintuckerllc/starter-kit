# Quick Start

## Prerequisites

- Amazon Web Services (AWS) account; [How do I create and activate a new AWS account?](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)

- Docker Hub Account; [Docker Hub](https://hub.docker.com/)

- Identify an AWS region and two AWS availablity zones (in the region) for the infasructure, e.g., *us-east-1*, *us-east-1a*, and *us-east-1b*; [Regions, Availability Zones, and Local Zones](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)

- AWS Identity Access and Management (IAM) user with administrator access, e.g., has *AdministratorAccess* policy; [Creating your first IAM admin user and group](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html)

- Amazon Route 53 hosted zone; This can be accomplished by registering a new domain; [Step 1: Register a domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html#getting-started-find-domain-name). This also can be accomplished by [Making Amazon Route 53 the DNS service for an existing domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html)

- AWS Certificate Manager public wild card certificate for the domain in the region; [Requesting a Public Certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)

- Workstation with latest Terraform CLI installed; [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

- Workstation with latest AWS CLI configured with the user with administrator access in the region; [Installing the AWS CLI version 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [Configuration basics](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)

- (Recommended) Workstation with Kubernetes CLI, *kubectl*, version 1.17 installed; [Install and Set Up kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Download Terraform Configurations

Two Terraform configurations, *pre-cluster* and *post-cluster*, are provided in the *tf* folder of the downloadable [starter-kit](https://github.com/larkintuckerllc/starter-kit) GitHub repository.

## Update Terraform Configurations' Variables

1. Copy the file *post-cluster/terraform.tfvars.sample* to *post-cluster/terraform.tfvars*

2. Edit the file *post-cluster/terraform.tfvars*

3. Update the value of the *certificate_arn* variable with the public wild card certificate ARN (from prerequisites); for example *arn:aws:acm:[obmitted]:[obmitted]:certificate/[obmitted]*

4. Update the value of the *zone_name* variable with the domain name associated with the host zone (from prerequisites); for example, *example.com*

5. Save the file

**note**: We will later update the other configuration's variables.

## Update Pre-Cluster Configuration Local Variables

1. Edit the file *pre-cluster/main.tf*

2. Update the value of the *az_0*  and *az_1* local variables with the availability zone names, e.g., *us-east-1a* and *us-east-1b*

3. Update the value of the *identifier* local variable with a regionally unique (in the account) name for the infrastructure. The name must be a valid hostname format; [hostname(7) — Linux manual page](https://man7.org/linux/man-pages/man7/hostname.7.html). For example, *starter-kit*

4. Update the value of the *region* local variable with the region name, e.g., *us-east-1*

5. Save the file

**note**: Unlike the Terraform configurations' variables, once the infrastructure is created the values of the local variables cannot be changed.

## Initialize Pre-Cluster Configuration

1. From the command-line in the *pre-cluster* folder, execute `terraform init`

## TODO

