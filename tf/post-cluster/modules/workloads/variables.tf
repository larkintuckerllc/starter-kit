variable "sk_version" {
  type = string
}

variable "workload" {
  type = map(object({
    external             = bool
    limits_cpu           = string
    limits_memory        = string
    liveness_probe_path  = string
    readiness_probe_path = string
    replicas             = number
    requests_cpu         = string
    requests_memory      = string
  }))
}
