variable "workload" {
  type = map(object({
    external = bool
  }))
}
