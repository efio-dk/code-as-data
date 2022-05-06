resource "aws_codepipeline" "this" {
  for_each = local.pipeline

  name     = "${local.name_prefix}${each.value.application}-${each.value.environment}"
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
      for_each = { for k, v in local.pipeline : k => v if k == each.key && v.source == "git" }

      content {
        name             = "${action.value.trigger}@${local.application[action.value.application].git.repository}"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source_output"]
        namespace        = "ns_source"

        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.this[local.application[action.value.application].git.connection].arn
          FullRepositoryId = "${local.application[action.value.application].git.owner}/${local.application[action.value.application].git.repository}"
          BranchName       = action.value.trigger
        }
      }
    }

    dynamic "action" {
      for_each = { for k, v in local.pipeline : k => v if k == each.key && v.source == "s3" }

      content {
        name             = "${action.value.trigger}@${local.application[action.value.application].s3.bucket}"
        category         = "Source"
        owner            = "AWS"
        provider         = "S3"
        version          = "1"
        output_artifacts = ["source_output"]
        namespace        = "ns_source"

        configuration = {
          S3Bucket    = local.application[action.value.application].s3.bucket
          S3ObjectKey = action.value.trigger
        }
      }
    }

    dynamic "action" {
      for_each = { for k, v in local.pipeline : k => v if k == each.key && v.source == "ecr" }

      content {
        name             = "${action.value.trigger}@${local.application[action.value.application].ecr.repository}"
        category         = "Source"
        owner            = "AWS"
        provider         = "ECR"
        version          = "1"
        output_artifacts = ["source_output"]
        namespace        = "ns_source"

        configuration = {
          RepositoryName = local.application[action.value.application].ecr.repository
          ImageTag       = action.value.trigger
        }
      }
    }

  }

  dynamic "stage" {
    for_each = length({ for k, v in local.action : k => v if v.application == each.value.application && v.stage == "build" }) > 0 ? [1] : []

    content {
      name = "Build"

      dynamic "action" {
        for_each = { for k, v in local.action : k => v if v.application == each.value.application && v.stage == "build" }

        content {
          name             = action.value.action
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["source_output"]
          version          = "1"
          run_order        = action.value.run_order
          output_artifacts = ["${action.value.action}_output"]
          namespace        = "ns_${action.value.stage}_${action.value.action}"

          configuration = {
            ProjectName = aws_codebuild_project.action[action.value.type].name
            EnvironmentVariables = jsonencode(concat(
              [
                for k, a in local.action : {
                  name : a.action,
                  value : "#{ns_${a.stage}_${a.action}.OUTPUT}"
                  type : "PLAINTEXT"
                } if a.application == action.value.application && a.run_order < action.value.run_order
              ],
              [
                {
                  "name" : "ENV",
                  "value" : each.value.environment,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "APP",
                  "value" : action.value.application,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "ACTION",
                  "value" : action.value.action,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "SRC",
                  "value" : local.application[action.value.application].action[action.value.action].src,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "DST",
                  "value" : action.value.ecr ? aws_ecr_repository.this[action.key].repository_url : local.application[action.value.application].action[action.value.action].dst,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "ARGS",
                  "value" : local.application[action.value.application].action[action.value.action].args,
                  "type" : "PLAINTEXT"
                },
            ]))
          }
        }
      }
    }
  }

  dynamic "stage" {
    for_each = length({ for k, v in local.action : k => v if v.application == each.value.application && v.stage == "deploy" }) > 0 ? [1] : []

    content {
      name = "Deploy"

      dynamic "action" {
        for_each = { for k, v in local.action : k => v if v.application == each.value.application && v.stage == "deploy" }

        content {
          name     = action.value.action
          category = "Build"
          owner    = "AWS"
          provider = "CodeBuild"
          input_artifacts = [
            lookup({ for value in values(local.action) : value.action => "${value.action}_output" if value.application == each.value.application && value.stage == "build" },
              local.application[action.value.application].action[action.value.action].src,
              "source_output"
            )
          ]
          # input_artifacts = concat(["source_output"],
          #   [for value in values(local.action) : "${value.action}_output" if value.application == each.value.application && value.stage == "build"]
          # )
          version   = "1"
          run_order = action.value.run_order
          namespace = "ns_${action.value.stage}_${action.value.action}"

          configuration = {
            # PrimarySource = lookup({ for value in values(local.action) : value.action => "${value.action}_output" if value.application == each.value.application && value.stage == "build" },
            #   local.application[action.value.application].action[action.value.action].src,
            #   "source_output"
            # )
            ProjectName = aws_codebuild_project.action[action.value.type].name
            EnvironmentVariables = jsonencode(concat(
              [
                for k, a in local.action : {
                  name : a.action,
                  value : "#{ns_${a.stage}_${a.action}.OUTPUT}"
                  type : "PLAINTEXT"
                } if a.application == action.value.application && a.run_order < action.value.run_order
              ],
              # [for key, val in local.env_vars[each.value.trigger] : {
              #   "name"  = key,
              #   "value" = val,
              #   "type"  = "PLAINTEXT"
              # }],
              [
                {
                  "name" : "ENV",
                  "value" : each.value.environment,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "APP",
                  "value" : action.value.application,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "ACTION",
                  "value" : action.value.action,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "SRC",
                  "value" : local.application[action.value.application].action[action.value.action].src,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "DST",
                  "value" : action.value.ecr ? aws_ecr_repository.this[action.key].repository_url : local.application[action.value.application].action[action.value.action].dst,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "ARGS",
                  "value" : local.application[action.value.application].action[action.value.action].args,
                  "type" : "PLAINTEXT"
                },

            ]))
          }
        }
      }
    }
  }

  dynamic "stage" {
    for_each = length({ for k, v in local.action : k => v if v.application == each.value.application && v.stage == "release" }) > 0 ? [1] : []

    content {
      name = "Release"

      dynamic "action" {
        for_each = { for k, v in local.action : k => v if v.application == each.value.application && v.stage == "release" }

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
            EnvironmentVariables = jsonencode(concat(
              [
                for k, a in local.action : {
                  name : a.action,
                  value : "#{ns_${a.stage}_${a.action}.OUTPUT}"
                  type : "PLAINTEXT"
                } if a.application == action.value.application && a.run_order < action.value.run_order
              ],
              [
                {
                  "name" : "ENV",
                  "value" : each.value.environment,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "SRC",
                  "value" : local.application[action.value.application].action[action.value.action].src,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "DST",
                  "value" : action.value.ecr ? aws_ecr_repository.this[action.key].repository_url : local.application[action.value.application].action[action.value.action].dst,
                  "type" : "PLAINTEXT"
                },
                {
                  "name" : "ARGS",
                  "value" : local.application[action.value.application].action[action.value.action].args,
                  "type" : "PLAINTEXT"
                },
            ]))
          }
        }
      }
    }
  }

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
