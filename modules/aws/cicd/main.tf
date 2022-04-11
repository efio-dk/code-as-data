locals {
  git_provider_map = {
    "github" : "GitHub"
    "github.com" : "GitHub"
    "bitbucket" : "Bitbucket"
    "bitbucket.org" : "Bitbucket"
    "s3" : "s3"
  }

  type_stage_map = {
    bootstrap : "build"
    docker_build : "build"
    terraform : "deploy"
  }

  config = defaults(var.config, {
    log_retention_in_days      = 7
    artifact_retention_in_days = 30
  })

  git_repository_breakdown = { for k, v in var.applications : k =>
    flatten(regexall("(github.com|bitbucket.org)[:\\/]([^\\/]+)\\/([^\\/]+)\\.git", v.git_repository_url)) if v.git_repository_url != null
  }

  application = { for app_name, app in var.applications : app_name => {
    git = app.git_repository_url != null ? {
      provider   = local.git_repository_breakdown[app_name][0]
      owner      = local.git_repository_breakdown[app_name][1]
      repository = local.git_repository_breakdown[app_name][2]
      connection = coalesce(app.git_connection, one(keys(local.config.git_connection)))
      trigger    = coalesce(app.git_trigger, { single = "main" })
    } : null
    s3 = app.s3_bucket != null ? {
      bucket  = app.s3_bucket
      trigger = app.s3_trigger
    } : null
    ecr = app.ecr_repository != null ? {
      repository = app.ecr_repository
      trigger    = app.ecr_trigger
    } : null
    action = { for name, val in app.action : name => {
      type      = val.type
      src       = val.source
      dst       = coalescee(val.target, "")
      args      = coalescee(val.custom_args, "")
      stage     = local.type_stage_map[val.type]
      run_order = coalescee(val.run_order, 1)
      # dst       = val.target != null ? val.target : ""
      # args      = val.custom_args != null ? val.custom_args : ""
      # run_order = val.run_order != null ? val.run_order : 1
    } }
  } }

  pipeline = { for e in flatten([for app_name, app in local.application : setunion(
    [for name, branch in coalesce(app.git.trigger, {}) : {
      source      = "git"
      application = app_name
      environment = name
      trigger     = branch
    }],
    [for name, objectkey in coalesce(app.s3.trigger, {}) : {
      source      = "s3"
      application = app_name
      environment = name
      trigger     = objectkey
    }],
    [for name, tag in coalesce(app.ecr.trigger, {}) : {
      source      = "ecr"
      application = app_name
      environment = name
      trigger     = tag
    }]

    )]) : "${e.application}/${e.environment}" => e
  }

  action = { for a in flatten([
    for app_name, app in local.application : [
      for action_name, action in app.action : {
        application = app_name
        action      = action_name
        stage       = action.stage
        type        = action.type
        ecr         = contains(["bootstrap", "docker_build"], action.type) && try(length(action.dst) == 0, true)
    }]]) : "${a.application}/${a.stage}/${a.action}" => a
  }

  build_image = local.config.build_image != null ? local.config.build_image : one([for k, v in local.action : "${aws_ecr_repository.this[k].repository_url}:latest" if v.ecr && v.type == "bootstrap"])
}
