data "aws_ssm_parameter" "token" {
  for_each = try(local.config.git.credentials.token_ssm_parameter, null) != null ? toset([""]) : []

  name = local.config.git.credentials.token_ssm_parameter
}

data "aws_ssm_parameter" "user_name" {
  for_each = try(local.config.git.credentials.user_name_ssm_parameter, null) != null ? toset([""]) : []

  name = local.config.git.credentials.user_name_ssm_parameter
}

resource "aws_codebuild_source_credential" "this" {
  for_each = try(local.config.git.credentials, null) != null ? toset([""]) : []

  auth_type   = local.config.git.credentials.provider == "GitHub" ? "PERSONAL_ACCESS_TOKEN" : "BASIC_AUTH"
  server_type = upper(local.config.git.credentials.provider)
  token       = data.aws_ssm_parameter.token[""].value
  user_name   = try(local.config.git.credentials.user_name_ssm_parameter, null) != null ? data.aws_ssm_parameter.user_name[""].value : null
}

resource "aws_codestarconnections_connection" "this" {
  for_each = local.config.git.connection != null ? local.config.git.connection : {}

  name          = "${local.config.name_prefix}${each.key}-git-connection"
  provider_type = each.value
  tags          = local.default_tags
}

resource "aws_codebuild_webhook" "this" {
  for_each = local.webhook

  project_name = aws_codebuild_project.git_to_s3[each.key].name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = each.value.cfg.event
    }

    filter {
      type    = "HEAD_REF"
      pattern = each.value.cfg.head_ref
    }

    dynamic "filter" {
      for_each = each.value.cfg.base_ref != null ? [1] : []
      content {
        type    = "BASE_REF"
        pattern = each.value.cfg.base_ref
      }
    }
  }

  depends_on = [
    aws_codebuild_project.git_to_s3,
    # aws_codebuild_source_credential.git
  ]
}
