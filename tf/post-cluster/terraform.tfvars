certificate_arn = " arn:aws:acm:us-east-1:143287522423:certificate/0bdf6587-ff6b-4cfb-a99d-239e0bb48908" # TODO: use [replace]
# TODO DEFAULTS?
workload        = {
  web0 = {
    destroy              = false
    liveness_probe_path  = "/"
    external             = true
    placeholder_image    = true
    placeholder_replicas = 1
    readiness_probe_path = "/"
  }
} # TODO: use {}
zone_name       = "todosrus.com" # TODO: use [replace]
