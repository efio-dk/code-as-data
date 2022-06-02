data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.this.id
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

locals {
  config = defaults(var.config, {
    cluster_version = "1.22"
  })

  fixed_addons = [
    "vpc-cni",
    "coredns",
    "kube-proxy"
  ]
  addons = concat(local.config.addons, local.fixed_addons)

  aws_auth_configmap_data = {
    mapRoles = yamlencode(concat([
      {
        rolearn  = aws_iam_role.worker.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ], local.config.aws_auth_configmap_data))
  }
}