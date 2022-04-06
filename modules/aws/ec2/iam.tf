data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_instance_connect_policy" {
  statement {
    actions   = ["ec2-instance-connect:SendSSHPublicKey"]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/ec2-instance-connect"
      values   = ["asg"]
    }
  }

  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"]
  }

  dynamic "inline_policy" {
    for_each = try(local.config.iam_role_permissions.inline_policies != null ? local.config.iam_role_permissions.inline_policies : [], [])

    content {
      name   = inline_policy.key
      policy = inline_policy.value
    }
  }

  managed_policy_arns = try(local.config.iam_role_permissions.managed_policies != null ? local.config.iam_role_permissions.managed_policies : [], [])

}

resource "aws_iam_role" "this" {
  name               = "${local.name_prefix}role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  inline_policy {
    name   = "ec2_instance_connect"
    policy = data.aws_iam_policy_document.ec2_instance_connect_policy.json
  }
  path = "/"
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name_prefix}profile"
  role = aws_iam_role.this.name
}
