data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "this" {
  count   = try(length(local.config.subnet_ids), 0) == 0 ? 1 : 0
  default = true
  state   = "available"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "this" {
  for_each = toset(data.aws_availability_zones.available.zone_ids)

  vpc_id               = data.aws_vpc.this[0].id
  availability_zone_id = each.key
  state                = "available"
  default_for_az       = true
}

locals {
  git_main_branch = try(local.config.default.git.main_branch != null ? local.config.default.git.main_branch : "main", "main")

  git_provider_map = {
    "github" : "GitHub"
    "github.com" : "GitHub"
    "bitbucket" : "Bitbucket"
    "bitbucket.org" : "Bitbucket"
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

  type_phase_map = {
    "docker_build" : "build"
  }

  git_repository_breakdown = { for k, v in var.applications2 : k =>
    flatten(regexall("(github.com|bitbucket.org)[:\\/]([^\\/]+)\\/([^\\/]+)\\.git", v.git_repository_url))
  }

  webhook = { for webhook in flatten([
    for app, val in local.app : [
      for env, cfg in val.webhook : {
        app        = app,
        env        = env,
        cfg        = cfg,
        provider   = val.provider,
        owner      = val.owner,
        repository = val.repository
      }
    ]
  ]) : "${webhook.app}/${webhook.env}" => webhook }

  action_type = toset(flatten([for k, v in local.app : [for a in v.action : a.type]]))

}

locals {
  debug = values(data.aws_subnet.this)[0].vpc_id

  default_tags = var.default_tags2

  config = defaults(var.config2, {
    name_prefix                = "efio-"
    log_retention_in_days      = 7
    artifact_retention_in_days = 30
  })

  app = { for k, v in var.applications2 : k => {
    provider           = local.git_repository_breakdown[k][0]
    owner              = local.git_repository_breakdown[k][1]
    repository         = local.git_repository_breakdown[k][2]
    git                = v.git
    branching_strategy = v.branching_strategy != null ? v.branching_strategy : "none"
    branch             = v.branching_strategy == "custom" ? v.branch : local.git_branching_strategy_map[v.branching_strategy].branch
    webhook            = v.branching_strategy == "custom" ? v.webhook : local.git_branching_strategy_map[v.branching_strategy].webhook
    action = { for name, val in v.action : name => {
      type  = val.type
      src   = val.src
      phase = val.phase != null ? val.phase : try(local.type_phase_map[val.type], name)
    } }
  } }
}
