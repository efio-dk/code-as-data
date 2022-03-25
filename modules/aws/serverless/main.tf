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

locals {
  debug = ""

  reg_acc = join(":", [data.aws_region.current.name, data.aws_caller_identity.current.account_id])

  default_tags = var.default_tags

  stage = replace(var.git_connection.branch, "/", "-")
}
