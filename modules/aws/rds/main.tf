
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

  major_engine_version = split(".", local.config.engine_version)[0]
}
