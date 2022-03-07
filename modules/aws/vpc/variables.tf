variable "default_tags2" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config2" {
  description = ""
  type = object({
    name_prefix = optional(string) # [a-z]
    vpc_cidr    = string

    availability_zone_count = optional(number)
    public_subnet_bits      = optional(number)
    private_subnet_bits     = optional(number)

    nat_mode                   = optional(string)
    flowlogs_retention_in_days = optional(number)
  })

  validation {
    condition     = var.config2.name_prefix == null || length(try(regexall("^[a-zA-Z-]*$", var.config2.name_prefix), " ")) > 0
    error_message = "`config.name_prefix` must satisfy pattern `^[a-zA-Z-]+$`."
  }

  validation {
    error_message = "`config.availability_zone_count` is invalid. Must be a number between 1 and 3."
    condition     = try(var.config2.availability_zone_count > 0 && var.config2.availability_zone_count < 4, true)
  }

  validation {
    error_message = "`config.vpc_cidr` is invalid. Must be valid CIDR range between /16 and /28."
    condition     = can(cidrnetmask(var.config2.vpc_cidr))
  }

  validation {
    condition     = try(contains(["ha_nat_gw", "single_nat_instance"], var.config2.nat_mode), true)
    error_message = "`config.nat_mode` is invalid. Valid values are [ha_nat_gw single_nat_instance]."
  }
}
