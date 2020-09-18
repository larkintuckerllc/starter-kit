locals {
  private_subnet_ids = [for subnet in values(aws_subnet.private) : subnet.id]
  public_subnet_ids = [for subnet in values(aws_subnet.public) : subnet.id]
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "subnet_ids" {
  value = concat(local.private_subnet_ids, local.public_subnet_ids)
}

output "vpc_id" {
  value = aws_vpc.this.id
}