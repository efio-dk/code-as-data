locals {
  config = defaults(var.config, {
    index_document         = "index.html"
    error_document         = "index.html"
    deploy_sample_document = false
    cache_policy           = "CachingOptimized"
    disable_cloudfront     = false
  })

  provision_kms = local.config.kms_arn != null ? 1 : 0
  kms_arn       = local.config.kms_arn != null ? local.config.kms_arn : aws_kms_key.this[0].arn
}
