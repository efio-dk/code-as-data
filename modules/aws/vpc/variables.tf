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

    trusted_ip_cidrs        = set(string)
    bastion_security_groups = optional(set(string))
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
