# Aurora

Amazon Aurora (Aurora) is a fully managed relational database engine that's compatible with MySQL and PostgreSQL.

We first create a sample *aurora* module with variables: *tf/post-cluster/modules/aurora/variables.tf*:

```hcl
variable "identifier" {
  type = string
}
```

The module's output consists of *database* attribute consisting of a map of objects with two attributes: *reader_url* and *url*. In this particular sample, it outputs a single database. The file: *tf/post-cluster/modules/aurora/outputs.tf*

```hcl
output "database" {
  value = {
    mydb = {
      reader_url = "postgres://${aws_rds_cluster.mydb.master_username}:${aws_rds_cluster.mydb.master_password}@${aws_rds_cluster.mydb.reader_endpoint}/mydb"
      url        = "postgres://${aws_rds_cluster.mydb.master_username}:${aws_rds_cluster.mydb.master_password}@${aws_rds_cluster.mydb.endpoint}/mydb"
    }
  }
}
```

This sample module create a single Aurora PostgreSQL cluster with a single instance. It depends on two Parameter Store parameters: *mydb_master_password* and *mydb_master_username*. The cluster instance is placed in a private subnet with a security group that only allows PostgreSQL traffic in from the EKS nodes. The file: *tf/post-cluster/modules/aurora/main.tf*

```hcl
data "aws_eks_cluster" "this" {
  name = var.identifier
}

data "aws_ssm_parameter" "mydb_master_password" {
  name = "mydb_master_password"
}

data "aws_ssm_parameter" "mydb_master_username" {
  name = "mydb_master_username"
}

data "aws_vpc" "this" {
  tags = {
    Infrastructure = var.identifier
  }
}

data "aws_subnet_ids" "this" {
  tags = {
    Infrastructure = var.identifier
    Tier           = "private"
  }
  vpc_id = data.aws_vpc.this.id
}

resource "aws_db_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = data.aws_subnet_ids.this.ids
  tags = {
    Infrastructure = var.identifier
  }
}

resource "aws_security_group" "this" {
  ingress {
    from_port   = 5432
    protocol    = "tcp"
    security_groups = [
      data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
    ]
    to_port     = 5432
  }
  name   = "${var.identifier}-postgresql"
  tags = {
    Infrastructure = var.identifier
    Name           = "${var.identifier}-postgresql"
  }
  vpc_id = data.aws_vpc.this.id
}

# MYDB

resource "aws_rds_cluster" "mydb" {
  cluster_identifier    = "mydb"
  database_name         = "mydb"
  db_subnet_group_name  = aws_db_subnet_group.this.name
  engine                = "aurora-postgresql"
  master_password       = data.aws_ssm_parameter.mydb_master_password.value
  master_username       = data.aws_ssm_parameter.mydb_master_username.value
  skip_final_snapshot   = true
  tags = {
    Infrastructure = var.identifier
  }
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
}

resource "aws_rds_cluster_instance" "mydb" {
  count                = 1
  cluster_identifier   = aws_rds_cluster.mydb.id
  db_subnet_group_name = aws_rds_cluster.mydb.db_subnet_group_name
  engine               = aws_rds_cluster.mydb.engine
  identifier           = "mydb-${count.index}"
  instance_class       = "db.r4.large"
  tags = {
    Infrastructure = var.identifier
  }
}
```

We reference the new module in *tf/post-cluster/main.tf*:

```hcl
module "aurora" {
  source      = "./modules/aurora"
  identifier  = var.IDENTIFIER
}
```

We add an output to the *tf/post-cluster/outputs.tf*. This is used to remind you what Aurora databases you created:

```hcl
output "aurora_ids" {
  value = [for id, database in module.aurora.database : id]
}
```

Next we need to update the *workloads* module to accept a new input *aurora_database*; *tf/post-cluster/modules/workloads/variables.tf*:

```hcl
variable "aurora_database" {
  type = map(object({
    reader_url = string
    url        = string
  }))
}
```

And in *tf/post-cluster/main.tf*:

```hcl
module "workloads" {
  source          = "./modules/workloads"
  aurora_database = module.aurora.database
  sk_version      = local.sk_version
  workload        = var.workload
}
```

We add in the environment variables to the container specification for workloads that have an aurora resource, i.e., adding in: *tf/post-cluster/modules/workloads/main.tf*:

```hcl
dynamic "env" { // RESOURCE AURORA URL
  for_each = [for resource in each.value["resources"] : resource["id"] if resource["type"] == "aurora"]
  content {
    name  = "${upper(env.value)}_AURORA_URL"
    value = var.aurora_database[env.value].url
  }
}
dynamic "env" { // RESOURCE AURORA READER_URL
  for_each = [for resource in each.value["resources"] : resource["id"] if resource["type"] == "aurora"]
  content {
    name  = "${upper(env.value)}_AURORA_READER_URL"
    value = var.aurora_database[env.value].reader_url
  }
}
```

Finally, we update our application code to use the environment variables, e.g,. *MYDB_AURORA_URL* or *MYDB_AURORA_READER_URL* to access the database.
