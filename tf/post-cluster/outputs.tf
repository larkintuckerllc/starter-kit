output "repository_urls" {
  value = module.cd.repository_urls
}

output "aurora_ids" {
  value = [for k, v in module.aurora.database : k]
}
