resource "kubernetes_config_map_v1_data" "aws_auth" {
  depends_on = [
    aws_eks_cluster.this,
    data.aws_eks_cluster_auth.eks
  ]

  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data
}