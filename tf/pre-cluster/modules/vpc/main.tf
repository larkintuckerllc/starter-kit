locals {
  vpc_cidr_block = "172.16.0.0/16"
  public_subnet = {
    public-0 = {
      availability_zone = var.availability_zones[0]
      cidr_block        = "172.16.0.0/24"
    }
    public-1 = {
      availability_zone = var.availability_zones[1]
      cidr_block        = "172.16.1.0/24"
    }
  }
}

# VPC

resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr_block
  tags = {
    Name    = var.identifier
    Project = var.identifier
  }
}

# SUBNETS

resource "aws_subnet" "public" {
  for_each = local.public_subnet
  availability_zone       = each.value["availability_zone"]
  cidr_block              = each.value["cidr_block"]
  map_public_ip_on_launch = true
  tags = {
    "kubernetes.io/cluster/${var.identifier}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
    Name                                      = "${var.identifier}-${each.key}"
    Infrastructure                            = var.identifier
    Tier                                      = "public"
  }
  vpc_id                  = aws_vpc.this.id
}

/*
resource "aws_subnet" "prv_0" {
  availability_zone = var.az_0
  cidr_block        = "172.16.128.0/18"
  tags = {
    "kubernetes.io/cluster/${var.identifier}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
    Name                                      = "${var.identifier}-prv_0"
    Project                                   = var.identifier
    Tier                                      = "Private"
  }
  vpc_id            = aws_vpc.this.id
}

resource "aws_subnet" "prv_1" {
  availability_zone = var.az_1
  cidr_block        = "172.16.192.0/18"
  tags = {
    "kubernetes.io/cluster/${var.identifier}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
    Name                                      = "${var.identifier}-prv_1"
    Project                                   = var.identifier
    Tier                                      = "Private"
  }
  vpc_id            = aws_vpc.this.id
}

# GATEWAYS

resource "aws_internet_gateway" "this" {
  tags = {
    Name    = var.identifier
    Project = var.identifier
  }
  vpc_id = aws_vpc.this.id
}

resource "aws_eip" "pub_0" {
  depends_on = [aws_internet_gateway.this]
  tags = {
    Name    = "${var.identifier}-pub_0"
    Project = var.identifier
  }
  vpc        = true
}

resource "aws_eip" "pub_1" {
  count      = var.ha ? 1 : 0
  depends_on = [aws_internet_gateway.this]
  tags = {
    Name    = "${var.identifier}-pub_1"
    Project = var.identifier
  }
  vpc        = true
}

resource "aws_nat_gateway" "pub_0" {
  allocation_id = aws_eip.pub_0.id
  subnet_id     = aws_subnet.pub_0.id
  tags = {
    Name    = "${var.identifier}-pub_0"
    Project = var.identifier
  }
}

resource "aws_nat_gateway" "pub_1" {
  count         = var.ha ? 1 : 0
  allocation_id = aws_eip.pub_1[0].id
  subnet_id     = aws_subnet.pub_1.id
  tags = {
    Name    = "${var.identifier}-pub_1"
    Project = var.identifier
  }
}

# ROUTE TABLES

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name    = "${var.identifier}-pub"
    Project = var.identifier
  }
}

resource "aws_route_table" "prv_0" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.pub_0.id
  }
  tags = {
    Name    = "${var.identifier}-prv_0"
    Project = var.identifier
  }
}

resource "aws_route_table" "prv_1" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.ha ? aws_nat_gateway.pub_1[0].id : aws_nat_gateway.pub_0.id
  }
  tags = {
    Name    = "${var.identifier}-prv_1"
    Project = var.identifier
  }
}

resource "aws_route_table_association" "pub_0" {
  subnet_id      = aws_subnet.pub_0.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "prv_0" {
  subnet_id      = aws_subnet.prv_0.id
  route_table_id = aws_route_table.prv_0.id
}

resource "aws_route_table_association" "prv_1" {
  subnet_id      = aws_subnet.prv_1.id
  route_table_id = aws_route_table.prv_1.id 
}

# NETWORK ACLS

resource "aws_network_acl" "this" {
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  subnet_ids = [
    aws_subnet.pub_0.id,
    aws_subnet.prv_0.id,
    aws_subnet.pub_1.id,
    aws_subnet.prv_1.id
  ]
  tags = {
    Name    = "${var.identifier}"
    Project = var.identifier
  }
  vpc_id     = aws_vpc.this.id
}
*/
