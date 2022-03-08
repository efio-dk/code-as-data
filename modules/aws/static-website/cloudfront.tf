resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "CloudFront identity for ${local.config.name_prefix}website"
}

resource "aws_cloudfront_distribution" "this" {
  count = local.config.disable_cloudfront ? 0 : 1

  depends_on = [
    aws_s3_bucket.this
  ]

  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_root_object = local.config.index_document
  aliases             = [] // [local.config.domain_name]
  wait_for_deployment = false
  tags                = local.default_tags

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "s3-cloudfront"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-cloudfront"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.this.id
  }

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # dynamic "viewer_certificate" {
  #   for_each = local.acm_certs
  #   content {
  #     acm_certificate_arn      = data.aws_acm_certificate.acm_cert[0].arn
  #     ssl_support_method       = "sni-only"
  #     minimum_protocol_version = "TLSv1"
  #   }
  # }

  # custom_error_response {
  #   error_code            = 403
  #   response_code         = 200
  #   error_caching_min_ttl = 0
  #   response_page_path    = "/"
  # }

}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-${local.config.cache_policy}"
}
