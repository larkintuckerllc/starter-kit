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

# TODO: FIX SECURITY GROUP TO CLUSTER
resource "aws_security_group" "this" {
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  name   = "${var.identifier}-postgresql"
  tags = {
    Infrastructure = var.identifier
    Name           = "${var.identifier}-postgresql"
  }
  vpc_id = data.aws_vpc.this.id
}
