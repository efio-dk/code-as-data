data "aws_iam_policy_document" "ecr" {

  statement {
    sid     = "GrantCiCdRoleFullControl"
    actions = ["ecr:*"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }
  }

  dynamic "statement" {
    for_each = { for k, v in local.config.ecr_permissions : k => v if v.pull }

    content {
      sid = "AllowCrossAccountPull"
      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }
    }
  }

  dynamic "statement" {
    for_each = { for k, v in local.config.ecr_permissions : k => v if v.push }

    content {
      sid = "AllowCrossAccountPush"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }
    }
  }
}

resource "aws_ecr_repository" "this" {
  for_each = { for k, v in local.action : k => v if v.ecr }

  name                 = "${local.name_prefix}${each.value.app}-${each.value.action}"
  image_tag_mutability = "MUTABLE"
  tags                 = local.default_tags

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.this.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name
  policy     = data.aws_iam_policy_document.ecr.json
}
