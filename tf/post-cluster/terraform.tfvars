certificate_arn = " arn:aws:acm:us-east-1:143287522423:certificate/0bdf6587-ff6b-4cfb-a99d-239e0bb48908" # TODO: use [replace]
workloads       = {
  ext0 = {
    external: true
  }
  ext1 = {
    external: true
  }
  int0 = {
    external: false
  }
} # TODO: use {}
zone_name       = "todosrus.com" # TODO: use [replace]