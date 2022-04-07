data "aws_iam_policy_document" "ecr" {

  statement {
    sid     = "GrantCiCdRoleFullControl"
    actions = ["ecr:*"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }
  }

  statement {
    sid = "AllowCrossAccountPull"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::382888529141:root"]
    }
  }

  // https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html


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
