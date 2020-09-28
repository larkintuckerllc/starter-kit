output "mydb_database_name" {
  value = aws_rds_cluster.mydb.database_name
}

output "mydb_endpoint" {
  value = aws_rds_cluster.mydb.endpoint
}

output "mydb_master_password" {
  value = aws_rds_cluster.mydb.master_password
}

output "mydb_master_username" {
  value = aws_rds_cluster.mydb.master_username
}
