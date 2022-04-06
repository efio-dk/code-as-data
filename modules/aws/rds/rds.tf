resource "aws_db_instance" "this" {
  allocated_storage    = local.config.volume_size
  engine               = local.config.engine
  engine_version       = local.config.engine_version
  instance_class       = local.config.instance_type
  name                 = local.config.db_name
  username             = local.config.username
  password             = aws_ssm_parameter.this.value
  # parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  copy_tags_to_snapshot = true
  db_subnet_group_name  = aws_db_subnet_group.this.id
  multi_az = local.config.multi_az

  tags = local.default_tags
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}db-group"
  subnet_ids = [aws_subnet.frontend.id, aws_subnet.backend.id]

  tags = local.default_tags
}