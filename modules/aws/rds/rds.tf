resource "aws_db_instance" "this" {
  identifier             = "${local.name_prefix}db"
  allocated_storage      = local.config.volume_size
  engine                 = local.config.engine
  engine_version         = local.config.engine_version
  instance_class         = local.config.instance_type
  db_name                = local.config.db_name
  username               = local.config.username
  password               = aws_ssm_parameter.this.value
  copy_tags_to_snapshot  = true
  db_subnet_group_name   = aws_db_subnet_group.this.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  multi_az               = local.config.multi_az

  tags = local.default_tags
}

resource "aws_db_subnet_group" "this" {
  name        = "${local.name_prefix}db-group"
  description = "DB subnet group for ${local.name_prefix}db"
  subnet_ids  = local.config.subnet_ids

  tags = local.default_tags
}

# resource "aws_db_option_group" "this" {
#   name                     =  "${local.name_prefix}option-group"
#   # option_group_description = "Terraform Option Group"
#   engine_name              = local.config.engine
#   major_engine_version     = local.major_engine_version

#   option {
#     option_name = "MARIADB_AUDIT_PLUGIN"

#     option_settings = [
#       {
#         name  = "SERVER_AUDIT_EVENTS"
#         value = "CONNECT"
#       },
#       {
#         name  = "SERVER_AUDIT_FILE_ROTATIONS"
#         value = "37"
#       },
#     ]
#   }
# }
