certificate_arn = "arn:aws:acm:us-east-1:143287522423:certificate/0bdf6587-ff6b-4cfb-a99d-239e0bb48908" # TODO: use [replace]
# SAMPLE WORKLOAD
workload        = {
  sample = {
    external             = true
    limits_cpu           = "100m"
    limits_memory        = "128Mi"
    liveness_probe_path  = "/"
    readiness_probe_path = "/"
    replicas             = 1
    requests_cpu         = "100m"
    requests_memory      = "128Mi"
  }
}
# workload        = {}
zone_name       = "todosrus.com" # TODO: use [replace]
