data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  default_tags = merge(var.default_tags, {
    "Terraform-module" : "code-as-data.com"
    tf-workspace = terraform.workspace
  })

  config = defaults(var.config, {
    name_prefix            = "cad-"
    index_document         = "index.html"
    error_document         = "index.html"
    deploy_sample_document = false
    cache_policy           = "CachingOptimized"
    disable_cloudfront     = false
  })
}
