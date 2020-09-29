output "database" {
  value = {
    mydb = {
      reader_url = "postgres://${aws_rds_cluster.mydb.master_username}:${aws_rds_cluster.mydb.master_password}@${aws_rds_cluster.mydb.reader_endpoint}/mydb"
      url        = "postgres://${aws_rds_cluster.mydb.master_username}:${aws_rds_cluster.mydb.master_password}@${aws_rds_cluster.mydb.endpoint}/mydb"
    }
  }
}
