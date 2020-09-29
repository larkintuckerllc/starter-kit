variable "certificate_arn" {
  type = string
}

variable "sk_version" {
  type = string
}

variable "workload" {
  type = map(object({
    external             = bool
    limits_cpu           = string
    limits_memory        = string
    liveness_probe_path  = string
    platform             = string
    readiness_probe_path = string
    replicas             = number
    requests_cpu         = string
    requests_memory      = string
    resources            = list(object({
      type = string
      id   = string
    }))
  }))
}

variable "zone_name" {
  type = string
}
