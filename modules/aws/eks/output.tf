output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = aws_eks_cluster.this.id
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = aws_eks_addon.this
}

output "worker_iam_arn" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = aws_iam_role.worker.arn
}