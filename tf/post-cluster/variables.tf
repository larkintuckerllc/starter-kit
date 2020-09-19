variable "certificate_arn" {
  type = string
}

variable "workloads" {
  type = map(object({
    external = bool
  }))
}

variable "zone_name" {
  type = string
}
