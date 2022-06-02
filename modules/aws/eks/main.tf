locals {
  config = defaults(var.config, {
    cluster_version = "1.22"
  })
}