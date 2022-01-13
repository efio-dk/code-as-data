resource "aws_security_group" "this" {
  name        = "${local.config.name_prefix}codebuild"
  description = "Used for ${local.config.name_prefix}codebuild projects"
  vpc_id      = data.aws_vpc.default[0].id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags, {
    Name = "${local.config.name_prefix}codebuild"
  })
}

## Git to S3 webhook & codebuild proj

resource "aws_codebuild_project" "git_to_s3" {
  for_each = local.webhook

  name = "${local.config.name_prefix}source-${each.value.app}-${each.value.env}"
  # description    = format(each.value.description, "${var.config.name_prefix}${each.value.name}")
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
    buildspec = templatefile("${path.module}/buildspec/webhook.yaml",
      {
        # region     = data.aws_region.current.name
        # account_id = data.aws_caller_identity.current.account_id
        # name       = "${local.config.name_prefix}source-${each.value.app}-${each.value.trigger}"
      }
    )
  }

  depends_on = [
    aws_s3_bucket.this,
    aws_iam_role.this
  ]
}

/*
## Codepipeline Action projects

data "aws_subnet" "this" {
  id = var.config.codebude_bild_subnet_id
}



resource "aws_codebuild_project" "action" {
  for_each = local.codebuild_action_projects

  name           = "${var.config.name_prefix}action-${each.key}"
  description    = each.value.description
  service_role   = aws_iam_role.cicd.arn
  tags           = local.default_tags
  encryption_key = aws_kms_key.this.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.cicd.name
      stream_name = "action/${each.key}"
      status      = "ENABLED"
    }
  }

  environment {
    compute_type                = each.value.compute_type
    image                       = each.value.build_image.image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = each.value.build_image.role

    environment_variable {
      name  = "DOCKER_CLI_EXPERIMENTAL"
      value = "enabled"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspec/${each.key}.yaml", {
      aws_account     = data.aws_caller_identity.current.account_id
      aws_region      = data.aws_region.current.name
      bb_ssm_username = var.config.ssm_git_username_key
      bb_ssm_password = var.config.ssm_git_password_key
      db_ssm_host     = ""
      db_ssm_token    = ""
      s3_artifact     = var.config.databricks_artifact # aws_s3_bucket.artifact.bucket
      kms_key_id      = aws_kms_key.this.id
    })
  }

  vpc_config {
    vpc_id             = data.aws_subnet.this.vpc_id
    subnets            = [data.aws_subnet.this.id]
    security_group_ids = [aws_security_group.action.id]
  }
}
*/