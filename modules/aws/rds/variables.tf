variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config" {
  description = ""
  type = object({
    name_prefix = optional(string) # [a-z]

    subnet_ids = set(string)

    engine         = string
    engine_version = optional(string)

    db_name       = optional(string)
    port          = optional(number)
    instance_type = optional(string)
    volume_size   = optional(number)
    multi_az      = optional(bool)

    username = optional(string)
  })

}

/*
module.nsph.module.db[0].module.db_instance.data.aws_iam_policy_document.enhanced_monitoring
module.nsph.module.db[0].module.db_instance.data.aws_partition.current
module.nsph.module.db[0].module.db_instance.aws_db_instance.this[0]
module.nsph.module.db[0].module.db_instance.aws_iam_role.enhanced_monitoring[0]
module.nsph.module.db[0].module.db_instance.aws_iam_role_policy_attachment.enhanced_monitoring[0]
module.nsph.module.db[0].module.db_instance.random_id.snapshot_identifier[0]
module.nsph.module.db[0].module.db_option_group.aws_db_option_group.this[0]
module.nsph.module.db[0].module.db_parameter_group.aws_db_parameter_group.this[0]
*/