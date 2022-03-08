provider "aws" {
  region  = local.config.region
  profile = local.config.profile
  assume_role {
    role_arn     = local.config.assume_role != null ? local.config.assume_role.role_arn : null
    session_name = local.config.assume_role != null ? local.config.assume_role.session_name : null
    external_id  = local.config.assume_role != null ? local.config.assume_role.external_id : null
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  debug = ""

  default_tags = merge(var.default_tags, {
    "Terraform-module" : "code-as-data.com"
    tf-workspace = terraform.workspace
  })
  config = defaults(var.config, {
    name_prefix                = "cad-"
    public_subnet_bits         = 28
    private_subnet_bits        = 27
    flowlogs_retention_in_days = -1
    nat_mode                   = "single_nat_instance"
  })

  availability_zone_count = length(data.aws_availability_zones.available.names)
  vpc_cidr_bits           = tonumber(regex("/(\\d+)$", local.config.vpc_cidr)[0])
  pub_sub_cidr_bits       = local.config.public_subnet_bits - local.vpc_cidr_bits - [0, 1, 2, 2][local.availability_zone_count - 1]
  prv_sub_cidr_bits       = local.config.private_subnet_bits - local.vpc_cidr_bits - [0, 1, 2, 2][local.availability_zone_count - 1]

  cidrs = cidrsubnets(local.config.vpc_cidr, local.pub_sub_cidr_bits, local.prv_sub_cidr_bits)

  subnet = { for net in setunion(
    [for idx in range(local.availability_zone_count) : {
      type              = "public"
      no                = idx
      availability_zone = data.aws_availability_zones.available.names[idx]
      cidr              = cidrsubnet(local.cidrs[0], local.config.public_subnet_bits - local.vpc_cidr_bits - local.pub_sub_cidr_bits, idx)
    }],
    [for idx in range(local.availability_zone_count) : {
      type              = "private"
      no                = idx
      availability_zone = data.aws_availability_zones.available.names[idx]
      cidr              = cidrsubnet(local.cidrs[1], local.config.private_subnet_bits - local.vpc_cidr_bits - local.prv_sub_cidr_bits, idx)
    }]
  ) : "${net.type}-${net.no}" => net }
}
