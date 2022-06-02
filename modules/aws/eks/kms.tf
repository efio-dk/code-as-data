data "aws_iam_policy_document" "kms" {
  statement {
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["*"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "cluster" {
  description         = "KMS CMK used by eks cluster."
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}eks-kms"
  })
}

resource "aws_kms_alias" "cluster" {
  name          = "alias/eks-cluster-kms-cmk"
  target_key_id = aws_kms_key.cluster.key_id
}
