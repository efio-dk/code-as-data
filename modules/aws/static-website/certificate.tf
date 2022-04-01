# data "aws_acm_certificate" "this" {
#   count = local.config.acm_certificate_arn != null ? 1 : 0

#   domain      = local.config.domain_name
#   most_recent = true
#   # provider = aws.aws_cloudfront
#   statuses = [
#     "ISSUED",
#   ]
# }

resource "aws_acm_certificate" "this" {
  count = local.config.acm_certificate_arn == null ? 1 : 0

  domain_name       = local.config.domain_name
  validation_method = "DNS"
  tags              = local.default_tags
}
