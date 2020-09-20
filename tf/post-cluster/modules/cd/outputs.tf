output "repository_urls" {
  value = [for repository in aws_codecommit_repository.this : {
    clone_url_http = repository.clone_url_http
    clone_url_ssh  = repository.clone_url_ssh
  }]
}
