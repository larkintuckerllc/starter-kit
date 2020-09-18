locals {
  public_subnet_ids = [for subnet in values(aws_subnet.public) : subnet.id]
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_ids" {
  value = concat(local.public_subnet_ids)
}

/*
output "subnet_ids_prv" {
  value = [
    aws_subnet.prv_0.id,
    aws_subnet.prv_1.id
  ]
}
*/
