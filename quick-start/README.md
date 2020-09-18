# Quick Start

## Prerequisites

- Amazon Web Services (AWS) account; [How do I create and activate a new AWS account?](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)

- Docker Hub Account; [Docker Hub](https://hub.docker.com/)

- AWS Identity Access and Management (IAM) user with administrator access, e.g., has *AdministratorAccess* policy; [Creating your first IAM admin user and group](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html)

- Amazon Route 53 hosted zone; This can be accomplished by registering a new domain; [Step 1: Register a domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html#getting-started-find-domain-name). This also can be accomplished by [Making Amazon Route 53 the DNS service for an existing domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html)

- AWS Certificate Manager public wild card certificate for the domain; [Requesting a Public Certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)

- Workstation with Terraform CLI installed; [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

- AWS CLI configured with the user with administrator access; [Installing the AWS CLI version 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [Configuration basics](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
