variable "certificate_arn" {
  type = string
}

variable "workload" {
  type = map(object({
    destroy              = bool
    external             = bool
    placeholder_image    = bool
    placeholder_replicas = number
  }))
}

variable "zone_name" {
  type = string
}
