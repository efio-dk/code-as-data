variable "default_tags2" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config2" {
  description = ""
  type = object({
    name_prefix = optional(string) # [a-z]
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
  })

}
