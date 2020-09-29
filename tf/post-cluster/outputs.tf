output "repository_urls" {
  value = module.cd.repository_urls
}

output "aurora_databases" {
  value = [for k, v in module.aurora.database : k]
}
