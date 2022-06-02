resource "aws_eks_addon" "this" {
  for_each = toset(local.addons)

  cluster_name      = aws_eks_cluster.this.name
  addon_name        = each.value
  resolve_conflicts = "OVERWRITE"

  lifecycle {
    ignore_changes = [
      modified_at
    ]
  }
}