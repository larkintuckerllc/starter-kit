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

- Workstation with Kubernetes CLI, *kubectl*, version 1.17 installed; [Install and Set Up kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

- Workstation with GIT CLI [1.5 Getting Started - Installing Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## Download Terraform Configurations

Two Terraform configurations, *pre-cluster* and *post-cluster*, are provided in the *tf* folder of the downloadable [starter-kit](https://github.com/larkintuckerllc/starter-kit) GitHub repository.

## Update Terraform Pre-Cluster Configuration's Constants

1. Edit the file *pre-cluster/main.tf*

2. Update the value of the *availablity_zones* local variable with the availability zone names, e.g., *us-east-1a* and *us-east-1b*

3. Update the value of the *identifier* local variable with a regionally unique (in the account) name for the infrastructure. The name must be a valid hostname format; [hostname(7) — Linux manual page](https://man7.org/linux/man-pages/man7/hostname.7.html). For example, *starter-kit*

4. Update the value of the *region* local variable with the region name, e.g., *us-east-1*

5. Save the file

**note**: Unlike the Terraform configurations' variables below, once the infrastructure is created the values of ## Update Terraform Pre-Cluster Configuration's Constants

## Update Terraform Post-Cluster Configuration's Constants

1. Edit the file *post-cluster/main.tf*

2. Update the value of the *identifier* local variable; matching value in *pre-cluster/main.tf*

3. Update the value of the *region* local variable; matching value in *pre-cluster/main.tf*

4. Save the file

## Update Terraform Post-Cluster Configurations' Variables

1. Edit the file *post-cluster/terraform.tfvars*

2. Update the value of the *certificate_arn* variable with the public wild card certificate ARN (from prerequisites); for example *arn:aws:acm:[obmitted]:[obmitted]:certificate/[obmitted]*

3. Update the value of the *zone_name* variable with the domain name associated with the host zone (from prerequisites); for example, *example.com*

4. Save the file

**note**: We will later update the other configuration's variables.

## Create Pre-Cluster Infrastructure

1. From the command-line in the *pre-cluster* folder, execute `terraform init`

2. From the command-line in the *pre-cluster* folder, execute `terraform apply`

## Access Kubernetes Cluster

1. From the commmand-line, execute `aws eks update-kubeconfig --region [replace] --name [replace]`; replace with region, e.g., *us-east-2*, and identifier, e.g., *starter-kit*

2. From the command-line, execute `kubectl get nodes` to confirm access to Kubernetes Cluster

## Authenticate Kubernetes Provider

1. From the command-line, execute `kubectl config current-context`; copy output

2. Edit the file *post-cluster/main.tf*

3. Update the value of *config-context* in the *kubernetes* provider block

4. Save the file

## Initialize Post-Cluster Configuration

1. From the command-line in the *post-cluster* folder, execute `terraform init`

## Import AWS Auth ConfigMap

1. From the command-line in the *post-cluster* folder, execute `terraform import module.cd.kubernetes_config_map.this kube-system/aws-auth`

## Re-Authenticate Kubernetes Provider

1. Edit the file *post-cluster/main.tf*

2. Comment the *kubernetes* provider block labeled with *FOR IMPORT ONLY*

3. Uncomment  the *kubernetes* provider block labeled with *FOR POST-IMPORT ONLY*

**note**: The Terraform *import* command does not support variables in provider blocks

## Create Post-Cluster Infrastructure

1. From the command-line in the *post-cluster* folder, execute `terraform apply`

## Create a Sample Workload

1. Edit the file *post-cluster/terraform.tfvars*

2. Replace the *workload* variable with a sample workload (see below)

3. From the command-line in the *post-cluster* folder, execute `terraform apply`; copy output

```hcl
workload        = {
  sample = {
    external             = true
    limits_cpu           = "100m"
    limits_memory        = "128Mi"
    liveness_probe_path  = "/"
    readiness_probe_path = "/"
    replicas             = 1
    requests_cpu         = "100m"
    requests_memory      = "128Mi"
  }
}
```

## Verify Sample Workload

1. From a browser, navigate to sample.[replace]; replacing with domain name associated with the host zone (from above), e.g., `sample.example.com`

## Setup SSH Connections to AWS CodeCommit

1. [Setup steps for SSH connections to AWS CodeCommit repositories on Linux, macOS, or Unix](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html)

**note:** Do not clone repository.

**note:** For Windows use [Setup steps for SSH connections to AWS CodeCommit repositories on Windows](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-windows.html)

## Download and Initialize Sample Image Code

1. Download sample image code; [Starter Kit Image Node.js](https://github.com/larkintuckerllc/starter-kit-image-nodejs)

2. From the downloaded folder, execute `git init`

3. From the downloaded folder, execute `git remote add aws [replace]`; replacing with the *clone_url_ssh* copied from above

**note**: By using the remote *aws*, one can continue to use *origin* for their own GIT repository.

## Update the Sample Image Code

1. In the downloaded folder, edit file *index.js*

2. Update the line *res.send('Hello World!');*; replacing the string *Hello World* as you please

3. Save the file

4. From the downloaded folder, execute `git add -A`

5. From the downloaded folder, execute `git commit -m "first commit"`

6. From the download folder, execute `git push aws master`

## Verify Updated Sample Workload

1. From a browser, navigate to sample.[replace]; replacing with domain name associated with the host zone (from above), e.g., `sample.example.com`

**note:** It will take a few minutes for the update to propogate.
