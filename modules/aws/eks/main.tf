locals {
  config = defaults(var.config, {
    cluster_version = "1.22"
  })

  fixed_addons = [
    "vpc-cni",
    # "coredns",
    "kube-proxy"
  ]
  addons = concat(local.config.addons, local.fixed_addons)
}