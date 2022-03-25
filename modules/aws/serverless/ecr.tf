resource "aws_ecr_repository" "registry" {
  for_each = local.functions

  name                 = "${var.name_prefix}${each.key}"
  image_tag_mutability = "MUTABLE"
  tags                 = var.default_tags

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.this.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_ecr_image" "this" {
  for_each = { for key, value in local.functions : key => value if value.image_tag != "" }

  registry_id     = aws_ecr_repository.registry[each.key].registry_id
  repository_name = aws_ecr_repository.registry[each.key].name
  image_tag       = local.functions[each.key].image_tag
}
