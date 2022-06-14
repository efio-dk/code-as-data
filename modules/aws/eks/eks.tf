### Cluster ###
resource "aws_eks_cluster" "this" {
  name     = "${local.name_prefix}cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = local.config.cluster_version

  vpc_config {
    subnet_ids              = local.config.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = local.config.api_allowed_ips
    security_group_ids      = [aws_security_group.master.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.cluster.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cluster"
  })

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name_prefix}nodes"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = local.config.subnet_ids

  scaling_config {
    desired_size = local.config.worker_node_count
    max_size     = local.config.worker_node_count
    min_size     = 1
  }

  ami_type       = "AL2_x86_64" # AL2_x86_64|AL2_x86_64_GPU|AL2_ARM_64
  instance_types = [local.config.worker_instance_type]
  # capacity_type = ON_DEMAND|SPOT
  disk_size = local.config.worker_volume_size
  # force_update_version - (Optional) Force version update if existing pods are unable to be drained due to a pod disruption budget issue.

  # labels - (Optional) Key-value map of Kubernetes labels. 
  # launch_template - (Optional) Configuration block with Launch Template settings. Detailed below.
  # remote_access - (Optional) Configuration block with remote access settings. Detailed below.
  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}nodegroup"
  })
  version = aws_eks_cluster.this.version

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes        = [scaling_config[0].desired_size]
    create_before_destroy = true
  }
}
