resource "aws_ecr_repository" "this" {
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
