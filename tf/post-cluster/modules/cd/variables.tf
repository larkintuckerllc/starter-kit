variable "identifier" {
  type = string
}

variable "workloads" {
  type = map(object({
    external = bool
  }))
}
