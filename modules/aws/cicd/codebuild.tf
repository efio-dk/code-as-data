## Git to S3 webhook & codebuild proj

resource "aws_codebuild_project" "git_to_s3" {
  for_each = { for k, v in local.env : k => v if v.source == "s3" }

  name           = "${local.config.name_prefix}source-${each.value.app}-${each.value.env}"
  description    = "Sources from ${each.value.provider} to S3 for \"${local.config.name_prefix}${each.value.app}-${each.value.env}\" pipeline"
  build_timeout  = "5"
  service_role   = aws_iam_role.this.arn
  tags           = local.default_tags
  encryption_key = aws_kms_key.this.arn

  artifacts {
    location  = aws_s3_bucket.this.id
    name      = "source-${each.value.app}-${each.value.env}.zip"
    packaging = "ZIP"
    type      = "S3"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.this.name
      stream_name = "source/${each.key}"
      status      = "ENABLED"
    }
  }

  source {
    type     = upper(local.git_provider_map[each.value.provider])
    location = "https://${each.value.provider}/${each.value.owner}/${each.value.repository}.git"

    git_clone_depth = 1
    buildspec       = file("${path.module}/buildspec/webhook.yaml")
  }

  depends_on = [
    aws_s3_bucket.this,
    aws_iam_role.this
  ]
}

## Codepipeline Action projects

resource "aws_codebuild_project" "action" {
  for_each = toset([for k, v in local.action : v.type])

  name           = "${local.config.name_prefix}action_${each.key}"
  description    = "Generic codebuild project for building ${each.key} actions."
  service_role   = aws_iam_role.this.arn
  tags           = local.default_tags
  encryption_key = aws_kms_key.this.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.this.name
      stream_name = "action/${each.key}"
      status      = "ENABLED"
    }
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image                       = contains(["bootstrap"], each.key) ? "aws/codebuild/amazonlinux2-x86_64-standard:3.0" : local.build_image
    image_pull_credentials_type = contains(["bootstrap"], each.key) ? null : "SERVICE_ROLE"

    environment_variable {
      name  = "DOCKER_CLI_EXPERIMENTAL"
      value = "enabled"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspec/${each.key}.yaml", {
      aws_account = data.aws_caller_identity.current.account_id
      aws_region  = data.aws_region.current.name
    })
  }

  dynamic "vpc_config" {
    for_each = data.aws_vpc.this

    content {
      vpc_id             = vpc_config.value.id
      subnets            = [for s in data.aws_subnet.this : s.id]
      security_group_ids = [for sg in aws_security_group.this : sg.id]
    }
  }
}
