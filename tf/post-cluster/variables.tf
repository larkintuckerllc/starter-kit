variable "certificate_arn" {
  type = string
}

variable "workload" {
  type = map(object({
    external       = bool
    ignore_changes = bool
  }))
}

variable "zone_name" {
  type = string
}
