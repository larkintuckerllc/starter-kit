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

/*
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.frontend.id, aws_subnet.backend.id]

  tags = {
    Name = "My DB subnet group"
  }
}
*/
