resource "aws_acm_certificate" "this" {
  count = local.config.acm_certificate_arn == null ? 1 : 0

  domain_name       = local.config.domain_name
  validation_method = "DNS"
  tags              = local.default_tags
}

locals {
  certificate_arn = coalesce(local.config.acm_certificate_arn, one(aws_acm_certificate.this).arn)
}
