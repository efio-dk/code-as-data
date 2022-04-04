variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config" {
  description = ""
  type = object({
    name_prefix   = optional(string) # [a-z]
    instance_type = string
    ami           = optional(string)
    volumes = optional(set(object({
      device_name = string
      size        = number
      type        = optional(string)
      iops        = optional(number)
      throughput  = optional(number)
    })))
    init_commands    = set(string)
    security_groups  = optional(set(string))
    min_size         = optional(number)
    max_size         = optional(number)
    desired_capacity = optional(number)

    private_subnets         = set(string)
    public_subnets          = optional(set(string))
    trusted_ssh_public_keys = optional(set(string))
  })
}
