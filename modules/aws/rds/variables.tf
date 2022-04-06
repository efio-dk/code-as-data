variable "config" {
  description = ""
  type = object({
    subnet_ids = set(string)

    engine         = string
    engine_version = optional(string)

    db_name       = optional(string)
    port          = optional(number)
    instance_type = optional(string)
    volume_size   = optional(number)
    multi_az      = optional(bool)

    username               = optional(string)
    client_security_groups = optional(set(string))
  })
}

/*
data.aws_iam_policy_document.enhanced_monitoring


aws_iam_role.enhanced_monitoring[0]
aws_iam_role_policy_attachment.enhanced_monitoring[0]

aws_db_option_group.this[0]
aws_db_parameter_group.this[0]
*/