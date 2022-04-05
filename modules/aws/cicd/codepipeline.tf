resource "aws_codepipeline" "this" {
  for_each = local.env

  name     = "${local.config.name_prefix}${each.value.app}-${each.value.env}"
  role_arn = aws_iam_role.this.arn
  tags     = local.default_tags

  artifact_store {
    location = aws_s3_bucket.this.id
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.this.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    dynamic "action" {
      for_each = length([for k, v in local.env : v if k == each.key && v.source == "s3"]) > 0 ? [1] : []

      content {
        name             = "codebuild-s3"
        category         = "Source"
        owner            = "AWS"
        provider         = "S3"
        version          = "1"
        output_artifacts = ["source_output"]
        namespace        = "ns_git_source"

        configuration = {
          S3Bucket    = aws_s3_bucket.this.id
          S3ObjectKey = "source-${each.value.app}-${each.value.env}.zip"
        }
      }
    }

    dynamic "action" {
      for_each = { for k, v in local.env : k => v if k == each.key && v.source == "codestar" }

      content {
        name             =  "${action.value.branch}@${action.value.repository}"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source_output"]
        namespace        = "ns_git_source"

        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.this[action.value.git].arn
          FullRepositoryId = "${action.value.owner}/${action.value.repository}"
          BranchName       = action.value.branch
        }
      }
    }
  }

  dynamic "stage" {
    for_each = length({ for k, v in local.action : k => v if v.app == each.value.app && v.stage == "build" }) > 0 ? [1] : []

    content {
      name = "Build"

      dynamic "action" {
        for_each = { for k, v in local.action : k => v if v.app == each.value.app && v.stage == "build" }

        content {
          name            = action.value.action
          category        = "Build"
          owner           = "AWS"
          provider        = "CodeBuild"
          input_artifacts = ["source_output"]
          version         = "1"
          run_order       = "1"
          namespace       = "ns_${action.value.stage}_${action.value.action}"

          configuration = {
            ProjectName = aws_codebuild_project.action[action.value.type].name
            EnvironmentVariables = jsonencode([
              {
                "name" : "SRC",
                "value" : local.app[action.value.app].action[action.value.action].src,
                "type" : "PLAINTEXT"
              },
              {
                "name" : "DST",
                "value" : action.value.ecr ? aws_ecr_repository.this[action.key].repository_url : local.app[action.value.app].action[action.value.action].dst,
                "type" : "PLAINTEXT"
              },
              {
                "name" : "ARGS",
                "value" : local.app[action.value.app].action[action.value.action].args,
                "type" : "PLAINTEXT"
              },
            ])
          }
        }
      }
    }
  }
  // test
  // release
  // deploy
  // validation


  #       content {
  #         name            = "${action.value.action}-${action.value.type}"
  #         category        = "Build"
  #         owner           = "AWS"
  #         provider        = "CodeBuild"
  #         input_artifacts = ["source_output"]
  #         version         = "1"
  #         run_order       = "1"

  #         configuration = {
  #           ProjectName = aws_codebuild_project.action[action.value.type].name

  #           EnvironmentVariables = jsonencode([
  #             {
  #               "name" : "PIPELINE",
  #               "value" : "${var.config.name_prefix}${each.value.name}-${each.value.trigger}"
  #               "type" : "PLAINTEXT"
  #             },
  #             {
  #               "name" : "SRC",
  #               "value" : action.value.path,
  #               "type" : "PLAINTEXT"
  #             },
  #             {
  #               "name" : "REGISTRY",
  #               "value" : action.value.image_registry != null ? action.value.image_registry : "",
  #               "type" : "PLAINTEXT"
  #             },
  #             {
  #               "name" : "IMAGE",
  #               "value" : "${action.value.name}-${action.value.action}",
  #               "type" : "PLAINTEXT"
  #             },
  #           ])
  #         }
  #       }
  #     }
  #   }
  # }

  # dynamic "stage" {
  #   for_each = length([
  #     for a in values(local.deploy_actions) : a
  #     if a.name == each.value.name
  #   ]) > 0 ? [1] : []

  #   content {
  #     name = "DeployTo${title(each.value.trigger)}"

  #     dynamic "action" {
  #       for_each = { for k, a in local.deploy_actions : k => a if a.name == each.value.name }

  #       content {
  #         name            = "${action.value.action}-${action.value.type}"
  #         category        = "Build"
  #         owner           = "AWS"
  #         provider        = "CodeBuild"
  #         input_artifacts = ["source_output"]
  #         version         = "1"
  #         run_order       = local.codebuild_action_projects[action.value.type].run_order
  #         namespace       = "ns-${action.value.action}"

  #         configuration = {
  #           ProjectName = aws_codebuild_project.action[action.value.type].name
  #           #   EnvironmentVariables = trimspace(jsonencode(concat(
  #           #     [for k, a in local.deploy_actions : {
  #           #       "name" : "${a.action}",
  #           #       "value" : "#{ns-${a.action}.OUTPUT}",
  #           #       "type" : "PLAINTEXT"
  #           #       } if a.name == each.value.name
  #           #       && local.codebuild_action_projects[action.value.type].run_order > local.codebuild_action_projects[a.type].run_order
  #           #     ],
  #           #     [for key, val in var.env_vars[each.value.trigger] : {
  #           #       "name"  = key,
  #           #       "value" = val,
  #           #       "type"  = "PLAINTEXT"
  #           #     }],
  #           #     [
  #           #       {
  #           #         "name" : "PIPELINE",
  #           #         "value" : "${var.config.name_prefix}${each.value.name}-${each.value.trigger}",
  #           #         "type" : "PLAINTEXT"
  #           #       },
  #           #       {
  #           #         "name" : "SRC",
  #           #         "value" : replace(action.value.path, "<env>", each.value.trigger),
  #           #         "type" : "PLAINTEXT"
  #           #       },
  #           #       {
  #           #         "name" : "ARGUMENTS",
  #           #         "value" : action.value.arguments == null ? "" : replace(action.value.arguments, "$env", each.value.trigger),
  #           #         "type" : "PLAINTEXT"
  #           #       },
  #           #   ])))
  #         }
  #       }
  #     }
  #   }
  # }

  depends_on = [
    aws_s3_bucket.this,
    aws_iam_role.this
  ]
}
