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
