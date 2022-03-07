data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Enable IAM User Permissions"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "Allow CodeBuild CloudWatch Logs"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.config.name_prefix}*"]
    }
  }
}

resource "aws_kms_key" "this" {
  description         = "KMS CMK used by ${local.config.name_prefix}solution."
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json
  tags = merge(local.default_tags, {
    "Name" = "${local.config.name_prefix}kms-cmk"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.config.name_prefix}kms-cmk"
  target_key_id = aws_kms_key.this.key_id
}
