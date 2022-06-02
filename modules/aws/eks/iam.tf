### Cluster IAM ###
data "aws_iam_policy_document" "cluster" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.name_prefix}eks-role"
  assume_role_policy = data.aws_iam_policy_document.cluster.json
}

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  name = "AmazonEKSClusterPolicy"
}
data "aws_iam_policy" "AmazonEKSVPCResourceController" {
  name = "AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = data.aws_iam_policy.AmazonEKSClusterPolicy.arn
  role       = aws_iam_role.cluster.name
}

# https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = data.aws_iam_policy.AmazonEKSVPCResourceController.arn
  role       = aws_iam_role.cluster.name
}

### Worker IAM ###
data "aws_iam_policy_document" "worker" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "worker" {
  name = "${local.name_prefix}worker"

  assume_role_policy = data.aws_iam_policy_document.worker.json
}

data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  name = "AmazonEKSWorkerNodePolicy"
}
data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  name = "AmazonEKS_CNI_Policy"
}
data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  name = "AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = data.aws_iam_policy.AmazonEKS_CNI_Policy.arn
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn
  role       = aws_iam_role.worker.name
}