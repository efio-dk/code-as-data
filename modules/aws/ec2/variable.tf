variable "config" {
  description = ""
  type = object({
    instance_type = string
    ami           = optional(string)
    volumes = optional(set(object({
      device_name = string
      mountpoint  = string
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

    vpc_id = string
    private_subnets         = set(string)
    public_subnets          = optional(set(string))
    trusted_ssh_public_keys = optional(set(string))
    kms_key                 = optional(string)

    iam_role_permissions = optional(object({
      managed_policies = optional(list(string))
      inline_policies  = optional(map(string))
    }))
  })
}
