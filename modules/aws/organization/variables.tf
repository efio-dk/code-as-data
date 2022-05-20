variable "config" {
  description = ""
  type = object({
    units = optional(list(string))
    accounts = optional(map(object({
      email     = string
      role_name = string
      unit      = optional(string)
    })))

    permission_sets = optional(map(object({
      description        = optional(string)
      relay_state        = optional(string)
      session_duration   = optional(string)
      inline_policy      = optional(string)
      policy_attachments = optional(list(string))
    })))

    account_assignments = optional(list(object({
      account        = optional(string)
      account_id     = optional(string)
      permission_set = string
      principal_name = string
      principal_type = string
    })))

    policies = optional(map(object({
      content = string
      targets = optional(list(object({
        target      = optional(string)
        target_type = string
      })))
    })))
  })

  validation {
    condition = alltrue([for k, v in var.config.accounts :
      can(v.unit) ? v.unit != null ? contains(var.config.units, v.unit) : true : true
    ])
    error_message = "One or more accounts referes to a non existing unit."
  }

  validation {
    condition = alltrue([for k, v in var.config.account_assignments :
      can(v.account_id) ? v.account_id == null ? lookup(var.config.accounts, v.account, null) != null : true : true
    ])
    error_message = "One or more account_assignments referes to a non existing account."
  }

  validation {
    condition = alltrue([for k, v in var.config.account_assignments :
      lookup(var.config.permission_sets, v.permission_set, null) != null
    ])
    error_message = "One or more account_assignments referes to a non existing permission_set."
  }
}