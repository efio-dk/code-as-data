variable "config" {
  description = ""
  type = object({
    build_image = optional(string)
    subnet_ids  = optional(set(string))

    log_retention_in_days      = optional(number)
    artifact_retention_in_days = optional(number)

    git = object({
      default = optional(object({
        main_branch        = optional(string)
        source             = optional(string)
        branching_strategy = optional(string)
      }))
      credentials = optional(object({
        provider                = string # BITBUCKET | GITHUB
        token_ssm_parameter     = string
        user_name_ssm_parameter = optional(string) # The Bitbucket username when the authType is BASIC_AUTH. This parameter is not valid for other types of source providers or connections.
      }))

      connection = optional(map(string))
    })

    iam_role_permissions = optional(object({
      power_user          = optional(bool)
      power_user_boundary = optional(bool)
      iam_nonuser_admin   = optional(bool)
      managed_policies    = optional(list(string))
      inline_policies     = optional(map(string))
    }))

    ecr_permissions = optional(map(object({
      account_id = string
      pull = boolean
      push = boolean
    })))
  })

  validation {
    condition     = contains(["GitHub", "Bitbucket"], try(var.config.git.credentials.provider, "GitHub"))
    error_message = "`config.git.credentials.provider` is invalid. Valid values are [GitHub Bitbucket]."
  }

  validation {
    condition = anytrue([
      try(var.config.git.credentials.provider, "") == "",
      try(var.config.git.credentials.provider, "") == "GitHub" && try(var.config.git.credentials.user_name_ssm_parameter, null) == null,
      try(var.config.git.credentials.provider, "") == "Bitbucket" && try(var.config.git.credentials.user_name_ssm_parameter, null) != null,
    ])
    error_message = "\"config.git.credentials.user_name_ssm_parameter\" must be set when \"provider\" is Bitbucket only."
  }

  validation {
    condition = alltrue([
      for k, v in var.config.git.connection != null ? var.config.git.connection : {} : length(regexall("^[a-zA-Z-_]*$", k)) > 0
    ])
    error_message = "`config.git.connection` key is invalid. Key must satisfy pattern `^[a-zA-Z0-9-_]+$`."
  }

  validation {
    condition     = length([for k, v in var.config.git.connection != null ? var.config.git.connection : {} : k if !contains(["GitHub", "Bitbucket"], v)]) == 0
    error_message = "`config.git.connection` is invalid. Valid values are [GitHub Bitbucket]."
  }
}

variable "applications" {
  description = ""
  type = map(object({
    git_repository_url = string
    git                = optional(string)
    branching_strategy = optional(string)

    branch = optional(map(string))
    webhook = optional(map(object({
      event    = string
      head_ref = string
      base_ref = optional(string)
    })))

    action = optional(map(object({
      stage       = optional(string)
      run_order   = optional(number)
      type        = string
      source      = string
      target      = optional(string)
      custom_args = optional(string)
    })))
  }))

  validation {
    condition = alltrue([for k, v in var.applications :
      length(flatten(regexall("(github.com|bitbucket.org)[:\\/]([^\\/]+)\\/([^\\/]+)\\.git", v.git_repository_url))) == 3
    ])
    error_message = "`applications[*].git_repository_url` does not seem to be a valid github or bitbucket repository url. Must satisfy '(github.com|bitbucket.org)[:\\/]([^\\/]+)\\/([^\\/]+)\\.git'."
  }

  validation {
    condition = alltrue([for k, v in var.applications :
      contains(["none", "single_branch", "main_develop", "pull_request", "tagging", "custom"], v.branching_strategy != null ? v.branching_strategy : "none")
    ])
    error_message = "`applications[*].branching_strategy` is invalid. Valid values are [none single_branch main_develop pull_request tagging custom]."
  }

  # validation {
  #   condition = alltrue([for k, v in var.applications :
  #     (v.git == null && (v.branching_strategy == null || v.branching_strategy == "none")) ||
  #     (v.git != null && length(regexall("^[a-zA-Z0-9-_]*$", v.git != null ? v.git : "")) > 0 && contains(["single_branch", "main_develop"], v.branching_strategy)) ||
  #     (v.git != null && length(regexall("^[a-zA-Z0-9-_]*$", v.git != null ? v.git : "")) > 0 && (v.branching_strategy == null || v.branching_strategy == "custom") && v.branch != null) ||
  #     (v.git == "credentials" && contains(["pull_request", "tagging"], v.branching_strategy)) ||
  #     (v.git == "credentials" && (v.branching_strategy == null || v.branching_strategy == "custom") && v.webhook != null) ||
  #     false
  #   ])
  #   error_message = "\"applications\" has invalid combination of \"git\", \"branching_strategy\", \"branch\" and \"webhook\"."
  # }
}
