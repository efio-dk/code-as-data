provider "aws" {
  region  = local.config.region
  profile = local.config.profile
  assume_role {
    role_arn     = local.config.assume_role != null ? local.config.assume_role.role_arn : null
    session_name = local.config.assume_role != null ? local.config.assume_role.session_name : null
    external_id  = local.config.assume_role != null ? local.config.assume_role.external_id : null
  }
}

locals {
  git_main_branch = try(local.config.default.git.main_branch != null ? local.config.default.git.main_branch : "main", "main")

  git_provider_map = {
    "github" : "GitHub"
    "github.com" : "GitHub"
    "bitbucket" : "Bitbucket"
    "bitbucket.org" : "Bitbucket"
    "s3" : "s3"
  }

  git_branching_strategy_map = {
    none : {
      branch : {}
      webhook : {}
    }

    single_branch : {
      branch : {
        prod = local.git_main_branch
      }
      webhook : {}
    }

    main_develop : {
      branch : {
        prod  = "main"
        stage = "development"
      }
      webhook : {}
    }

    pull_request : {
      branch : {}
      webhook : {
        prod = {
          event    = "PUSH"
          head_ref = "^refs/heads/${local.git_main_branch}"
          base_ref = null
        }
        stage = {
          event    = "PULL_REQUEST_CREATED,PULL_REQUEST_UPDATED,PULL_REQUEST_REOPENED"
          head_ref = "^refs/heads/*"
          base_ref = "^refs/heads/${local.git_main_branch}"
        }
      }
    }

    tagging : {
      branch : {}
      webhook : {
        prod = {
          event    = "PUSH"
          head_ref = "^refs/tags/v*"
          base_ref = null
        }
        stage = {
          event    = "PUSH"
          head_ref = "^refs/heads/*"
          base_ref = null
        }
      }
    }
  }

  type_stage_map = {
    "bootstrap" : "build"
    "docker_build" : "build"
    silent_terraform : "deploy"
    terraform_deploy : "deploy"
    // tf plan
    // manual approve
    // tf apply

    // build
    // test
    // release
    // deploy
    // validation
  }

}

locals {
  debug = local.build_image

  default_tags = merge(var.default_tags, {
    "Terraform-module" : "code-as-data.com"
    tf-workspace = terraform.workspace
  })

  config = defaults(var.config, {
    name_prefix                = "cad-"
    log_retention_in_days      = 7
    artifact_retention_in_days = 30
  })

  git_repository_breakdown = { for k, v in var.applications : k =>
    flatten(regexall("(github.com|bitbucket.org)[:\\/]([^\\/]+)\\/([^\\/]+)\\.git", v.git_repository_url))
  }

  app = { for k, v in var.applications : k => {
    provider           = local.git_repository_breakdown[k][0]
    owner              = local.git_repository_breakdown[k][1]
    repository         = local.git_repository_breakdown[k][2]
    git                = v.git
    branching_strategy = v.branching_strategy != null ? v.branching_strategy : "none"
    branch             = v.branching_strategy == "custom" ? v.branch : local.git_branching_strategy_map[v.branching_strategy].branch
    webhook            = v.branching_strategy == "custom" ? v.webhook : local.git_branching_strategy_map[v.branching_strategy].webhook
    action = { for name, val in v.action : name => {
      type      = val.type
      src       = val.source
      dst       = val.target != null ? val.target : ""
      args      = val.custom_args != null ? val.custom_args : ""
      stage     = local.type_stage_map[val.type]
      run_order = val.run_order != null ? val.run_order : 1
    } }
  } }

  env = { for e in flatten([for app_name, app in local.app : setunion(
    [for env, webhook in app.webhook : {
      app    = app_name
      env    = env
      source = "s3"

      provider   = local.git_repository_breakdown[app_name][0]
      owner      = local.git_repository_breakdown[app_name][1]
      repository = local.git_repository_breakdown[app_name][2]
      webhook    = webhook
    }],
    [for env, branch in app.branch : {
      app        = app_name
      env        = env
      source     = "codestar"
      git        = app.git
      owner      = local.git_repository_breakdown[app_name][1]
      repository = local.git_repository_breakdown[app_name][2]
      branch     = branch
    }])]) : "${e.app}/${e.env}" => e
  }

  action = { for a in flatten([
    for app_name, app in local.app : [
      for action_name, action in app.action : {
        app    = app_name
        action = action_name
        stage  = action.stage
        source = try(length(app.webhook) > 0 ? "s3" : "codestar", "codestar")
        type   = action.type
        ecr    = contains(["bootstrap"], action.type) && try(length(action.dst) == 0, true)
    }]]) : "${a.app}/${a.stage}/${a.action}" => a
  }

  build_image = local.config.build_image != null ? local.config.build_image : one([for k, v in local.action : "${aws_ecr_repository.this[k].repository_url}:latest" if v.ecr && v.type == "bootstrap"])
}
