locals {
  config = defaults(var.config, {
    index_document         = "index.html"
    error_document         = "index.html"
    deploy_sample_document = false
    cache_policy           = "CachingOptimized"
    disable_cloudfront     = false
  })
}
