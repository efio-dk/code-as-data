resource "aws_acm_certificate" "this" {
  # count    = local.config.acm_certificate_arn == null ? 1 : 0

  domain_name       = "www.efio.dk"
  validation_method = "DNS"
  tags              = local.default_tags
}
