# Under the Hood

## System Manager Parameters

- *dockerhub_username*: DockerHub username

- *dockerhub_password*: DockerHub password

## Amazon Virtual Private Cloud (VPC)

The Amazon infrastructure includes:

- Region

- Availability Zone (AZ) x 2

The VPC infrastructure includes:

- VPC: 172.16.0.0/16

- Subnet (SN) Private: 172.16.128.0/18

- Subnet (SN) Private: 172.16.192.0/18

- Subnet (SN) Public: 172.16.0.0/24

- Subnet (SN) Public: 172.16.1.0/24

- Internet Gateway (IG)

- NAT Gateway (NG) x 2

![vpc](img/vpc.png)

The VPC infrastructure also includes:

- Route Table Private x 2 (associated with subnet private)

| Destination   | Target |
| ------------- | ------ |
| 172.16.0.0/16 | local  |
| 0.0.0.0/0     | NG     |

- Route Table Public (associated with subnet public x 2)

| Destination   | Target |
| ------------- | ------ |
| 172.16.0.0/16 | local  |
| 0.0.0.0/0     | IG     |

- Network Access Control List (associated with subnet private x 2 and subnet public x 2):

Inbound:

| Rule | Type        | Source      | Allow/Deny |
| ---- | ----------- | ----------- | ---------- |
| 100  | All Traffic | 0.0.0.0/0   | ALLOW      |
| *    | All Traffic | 0.0.0.0/0   | DENY       |

Outbound:

| Rule | Type        | Destination | Allow/Deny |
| ---- | ----------- | ----------- | ---------- |
| 100  | All Traffic | 0.0.0.0/0   | ALLOW      |
| *    | All Traffic | 0.0.0.0/0   | DENY       |

## Amazon Elastic Kubernetes Service (EKS)

The cluster infrastructure includes:

- EKS Kubernetes Control Plane (CP)

- Node Group (NG); backed by an EC2 auto scaling group and EC2 launch template

- Nodes (ND); the managed EC2 instances provided by the node group

- Network Interfaces (NI); in addition to the network interfaces associated with the EC2 instances there are two addition network interfaces. Based on the security group configuration (below), these network interfaces appear to enable the control plane to communicate with the nodes

**note**: One of the two additional network interfaces appeared in a public subnet; not sure why.

- Security Group (orange); EKS creates a security group:

Inbound:

| Type        | Source    |
| ----------- | --------- |
| All Traffic | orange SG |

Outbound:

| Type        | Destination |
| ----------- | ----------- |
| All Traffic | 0.0.0.0/0   |

![cluster](img/cluster.png)

The cluster infrastructure also includes:

- Cluster IAM Role; provides EKS permissions

- Node Instance IAM Role; provides Nodes permissions

- IAM OpenID Connect Identify Provider; enables IAM roles for service accounts

## Continuous Integration

The continuous integration infrastructure includes:

- S3 Bucket (BK); storing CodePipeline artifacts

![CD](img/cd.png)

## ALB Ingress Controller

The ALB Ingress controller includes [alb-ingress-controller resources](https://registry.terraform.io/modules/iplabs/alb-ingress-controller/kubernetes/3.0.2?tab=resources).

![ALB](img/alb.png)

## AWS Auth ConfigMap

Elastic Kubernetes Service (EKS) creates a ConfigMap, *aws-auth*, in the *kube-system* namespace.

[Managing users or IAM roles for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)

## Workloads

The workloads infrastructure includes:

- Application Load Balancer (ALB); created by ALB ingress controller

- Security Group (purple); ALB ingress controller creates a security group:

Inbound:

| Type        | Source    |
| ----------- | --------- |
| HTTP        | 0.0.0.0/0 |
| HTTPS       | 0.0.0.0/0 |

Outbound:

| Type        | Destination |
| ----------- | ----------- |
| All Traffic | 0.0.0.0/0   |

- Updated Security Group (orange); ALB ingress controller updates a security group:

Inbound:

| Type        | Source    |
| ----------- | --------- |
| All Traffic | orange SG |
| All TCP     | purple SG |

Outbound:

| Type        | Destination |
| ----------- | ----------- |
| All Traffic | 0.0.0.0/0   |

Each workload infrastructure includes:

- CodeCommit Repository (CRP)

- Elastic Container Repository (ERP)

- CodeBuild Project (PRJ)

- CodePipeline Pipeline (PL)

- Route 53 DNS Zone A Record (A)

![workload aws](img/wl-aws.png)

The workloads infrastructure also includes:

- Kubernetes Ingress (ING) in the *default* namespace

Each workload infrastructure also includes:

- Kubernetes Deployment (DPY) in the *default* namespace

- Kubernetes Service (SVC) in the *default* namespace

![workload cluster](img/wl-cluster.png)

Each workload infrastructure also includes:

- CodePipeline IAM ROLE

- CodeBuild IAM ROLE

- Kubernetes Role in the *default* namespace; allows for CodeBuild IAM Role to update deployment

- Kubernetes RoleBinding in the *default* namespace; allows for CodeBuild IAM Role to update deployment

## Dockerfiles

The continous deployment builds use the following Dockerfiles:

### Go

```Dockerfile
FROM golang:1.14 AS builder
WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install -v ./cmd/...

FROM alpine:3.12
COPY --from=builder /go/bin/* /usr/local/bin/
EXPOSE 8080
USER 1000:1000
ENV PORT=8080
CMD ["app"]
```

### Node.js

```Dockerfile
FROM node:12.18.2
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8080
USER 1000:1000
ENV PORT=8080
CMD [ "npm", "start" ]
```
