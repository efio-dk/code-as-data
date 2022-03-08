provider "aws" {
  region  = local.config.region
  profile = local.config.profile
  assume_role {
    role_arn     = local.config.assume_role != null ? local.config.assume_role.role_arn : null
    session_name = local.config.assume_role != null ? local.config.assume_role.session_name : null
    external_id  = local.config.assume_role != null ? local.config.assume_role.external_id : null
  }
}

provider "aws" {
  alias   = "use1"
  region  = "us-east-1"
  profile = local.config.profile
  assume_role {
    role_arn     = local.config.assume_role != null ? local.config.assume_role.role_arn : null
    session_name = local.config.assume_role != null ? local.config.assume_role.session_name : null
    external_id  = local.config.assume_role != null ? local.config.assume_role.external_id : null
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  debug = ""

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
  })
}
