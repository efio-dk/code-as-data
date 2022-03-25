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
    sid       = "Allow Lambda CloudWatch Logs"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.reg_acc}:log-group:/aws/lambda/${var.name_prefix}*"]
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
      "kms:DescribeKey"
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.reg_acc}:log-group:/aws/codebuild/${var.name_prefix}cicd"]
    }
  }

  statement {
    sid       = "Allow SNS"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:sns:${local.reg_acc}:${var.name_prefix}*"]
    }
  }

  ### ? 

  # statement {
  #   sid       = "Allow SQS"
  #   resources = ["*"]
  #   actions = [
  #     "kms:Encrypt",
  #     "kms:Decrypt",
  #     "kms:ReEncrypt*",
  #     "kms:GenerateDataKey*",
  #     "kms:DescribeKey"
  #   ]

  #   principals {
  #     type        = "Service"
  #     identifiers = ["sqs.amazonaws.com"]
  #   }

  #   # condition {
  #   #   test     = "ArnEquals"
  #   #   variable = "kms:EncryptionContext:aws:logs:arn"
  #   #   values   = ["arn:aws:logs:${local.reg_acc}:log-group:/aws/codebuild/${var.name_prefix}cicd"]
  #   # }
  # }

  ### Lambda 

  statement {
    sid       = "Allow lambda"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    # condition {
    #   test     = "ArnEquals"
    #   variable = "kms:EncryptionContext:aws:logs:arn"
    #   values   = ["arn:aws:logs:${local.reg_acc}:log-group:/aws/codebuild/${var.name_prefix}cicd"]
    # }
  }
}

resource "aws_kms_key" "this" {
  description         = "KMS CMK used by ${var.name_prefix}solution"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json
  tags = merge(var.default_tags, {
    "Name" = "${var.name_prefix}kms-cmk"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}kms-cmk"
  target_key_id = aws_kms_key.this.key_id
}
