variable "certificate_arn" {
  type = string
}

variable "workload" {
  type = map(object({
    external = bool
  }))
}

variable "zone_name" {
  type = string
}
