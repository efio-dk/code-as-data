provider "aws" {
  region  = local.config.region
  profile = local.config.profile
  assume_role {
    role_arn     = local.config.assume_role != null ? local.config.assume_role.role_arn : null
    session_name = local.config.assume_role != null ? local.config.assume_role.session_name : null
    external_id  = local.config.assume_role != null ? local.config.assume_role.external_id : null
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  debug = ""

  default_tags = merge(var.default_tags, {
    "Terraform-module" : "code-as-data.com"
    tf-workspace = terraform.workspace
  })

  config = defaults(var.config, {
    name_prefix   = "cad-"
    enable_signup = false
  })
}
