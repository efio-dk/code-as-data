# resource "aws_db_instance" "this" {
#   allocated_storage    = local.config.volume_size
#   engine               = local.config.engine
#   engine_version       = local.config.engine_version
#   instance_class       = local.config.instance_type
#   name                 = local.config.db_name
#   username             = local.config.username
#   password             = aws_ssm_parameter.this.value
#   # parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true

#   copy_tags_to_snapshot = true
#   db_subnet_group_name  = aws_db_subnet_group.this.id
#   multi_az = local.config.multi_az

#   tags = local.default_tags
# }

resource "aws_db_subnet_group" "this" {
  name       = "${local.config.name_prefix}db-group"
  subnet_ids = local.config.subnet_ids

  tags = local.default_tags
}

# resource "aws_db_option_group" "this" {
#   name                     =  "${var.name_prefix}option-group"
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