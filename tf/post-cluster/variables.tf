variable "certificate_arn" {
  type = string
}

variable "workload" {
  type = map(object({
    destroy              = bool
    external             = bool
    liveness_probe_path  = string
    placeholder_image    = bool
    placeholder_replicas = number
    readiness_probe_path = string
  }))
}

variable "zone_name" {
  type = string
}
