resource "random_password" "this" {
  length  = 24
  special = false
  # override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "this" {
  name        = "/${local.config.name_prefix}secrets/rds-password"
  description = "The RDS master password."
  type        = "SecureString"
  value       = random_password.this.result
  tags        = local.default_tags
}
