data "aws_subnet" "this" {
  for_each = local.config.subnet_ids

  id = each.value
}

locals {
  config = defaults(var.config, {
    port           = 3306
    engine         = "mysql"
    engine_version = "8.0"
    instance_type  = "db.t3.small"
    volume_size    = 30
    multi_az       = false
    username       = "admin"
  })

  vpc_id = one(distinct([for subnet in data.aws_subnet.this : subnet.vpc_id]))

  major_engine_version = split(".", local.config.engine_version)[0]
}
