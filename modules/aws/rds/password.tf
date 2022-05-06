resource "random_password" "this" {
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "this" {
  name        = "/${local.name_prefix}secrets/rds-password"
  description = "The RDS master password."
  type        = "SecureString"
  value       = random_password.this.result
  tags        = local.default_tags
}
