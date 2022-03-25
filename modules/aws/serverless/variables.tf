variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config" {
  description = ""
  type = object({
    region  = optional(string)
    profile = optional(string)
    assume_role = optional(object({
      role_arn     = string
      session_name = string
      external_id  = string
    }))

    name_prefix = optional(string) # [a-z]
    vpc_cidr    = string

    availability_zone_count = optional(number)
    public_subnet_bits      = optional(number)
    private_subnet_bits     = optional(number)

    nat_mode                   = optional(string)
    flowlogs_retention_in_days = optional(number)
  })

  validation {
    condition     = var.config.name_prefix == null || length(try(regexall("^[a-zA-Z-]*$", var.config.name_prefix), " ")) > 0
    error_message = "`config.name_prefix` must satisfy pattern `^[a-zA-Z-]+$`."
  }

  validation {
    error_message = "`config.availability_zone_count` is invalid. Must be a number between 1 and 3."
    condition     = try(var.config.availability_zone_count > 0 && var.config.availability_zone_count < 4, true)
  }

  validation {
    error_message = "`config.vpc_cidr` is invalid. Must be valid CIDR range between /16 and /28."
    condition     = can(cidrnetmask(var.config.vpc_cidr))
  }

  validation {
    condition     = try(contains(["ha_nat_gw", "single_nat_instance"], var.config.nat_mode), true)
    error_message = "`config.nat_mode` is invalid. Valid values are [ha_nat_gw single_nat_instance]."
  }
}






# variable "default_tags" {
#   description = "A map of default tags, that will be applied to all resources applicable."
#   type        = map(string)
#   default     = {}
# }

# variable "name_prefix" {
#   description = "A name prefix that will be applied to all named resources."
#   type        = string
#   default     = "efio-"
# }

# variable "git_connection" {
#   description = ""
#   type = object({
#     provider   = string
#     owner      = string
#     repository = string
#     branch     = string
#   })
#   default = null
# }

# variable "cloudwatch_log_retention_in_days" {
#   description = "The cloudwatch log retention period in days for log enabled resources."
#   default     = 7
# }

# variable "queues" {
#   description = "A map of sqs-queues to be created."
#   type = map(object({
#     visibility_timeout_seconds = optional(number)
#     message_retention_seconds  = optional(number)
#     delay_seconds              = optional(number)
#     receive_wait_time_seconds  = optional(number)

#     sns_subscriptions = optional(map(object({})))
#   }))
#   default = {}
# }

# variable "topics" {
#   description = "A map of sns-topics to be created."
#   type = map(object({
#     fifo = optional(bool)
#   }))
#   default = {}
# }

# variable "functions" {
#   description = "A map of lambda-functions to be created."
#   type = map(object({
#     description     = string
#     src_path        = string
#     image_tag       = optional(string)
#     timeout         = optional(number)
#     memory_size     = optional(number)
#     subnets         = optional(string)
#     security_groups = optional(string)
#     inline_policies = optional(map(string))

#     environment_variables = optional(map(object({
#       value = string
#       type  = string
#     })))

#     permissions = optional(map(object({
#       actions  = list(string)
#       resource = string
#     })))

#     events = optional(object({
#       sns = optional(map(object({})))
#       sqs = optional(map(object({
#         batch_size                         = optional(number)
#         maximum_batching_window_in_seconds = optional(number)
#       })))
#       schedules = optional(map(object({
#         cron = string
#       })))
#       https = optional(map(object({
#         method = string
#         path   = string
#         public = bool
#         # timeout_milliseconds 
#         # throttle
#       })))
#     }))

#     targets = optional(map(object({
#       env_var_key = string
#       type        = string
#     })))
#   }))
# }

# variable "image_tags" {
#   description = "A map of container image tags. Use function name as key and tag as value."
#   type        = map(string)
#   default     = {}
# }

# variable "default_image_tag" {
#   description = "A image tags for a function"
#   type        = string
#   default     = null
# }

# variable "cognito_config" {
#   type = object({

#     password_policy = object({
#       minimum_length                   = number
#       require_lowercase                = bool
#       require_numbers                  = bool
#       require_symbols                  = bool
#       require_uppercase                = bool
#       temporary_password_validity_days = number
#     })
#   })
#   default = null
# }