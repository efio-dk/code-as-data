data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  default_tags = merge(var.default_tags, {
    "Terraform-module" : "code-as-data.com"
    tf-workspace = terraform.workspace
  })

  config = defaults(var.config, {
    port = 3306
    engine = "mysql"
    engine_version = "8.0"
    instance_type = "db.t3.small"
    instance_volume = 30
    multi_az = false
    username = "admin"
  })
}