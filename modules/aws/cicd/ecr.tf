resource "aws_ecr_repository" "this" {
  for_each = { for k, v in local.action : k => v if v.ecr }

  name                 = "${local.config.name_prefix}cicd-image"
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
