data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  debug = ""

  default_tags = merge(var.default_tags2, {
    "Terraform-module" : "code-as-data.com"
    tf-workspace = terraform.workspace
  })

  config = defaults(var.config2, {
    name_prefix            = "cad-"
    index_document         = "index.html"
    error_document         = "index.html"
    deploy_sample_document = false
    cache_policy           = "CachingOptimized"
  })
}
