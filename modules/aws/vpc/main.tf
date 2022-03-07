data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # debug = aws_nat_gateway.this
  # debug = aws_subnet.this
  debug = local.route

  default_tags = merge(var.default_tags2, {
    "Terraform-module" : "code-as-data.com"
    tf-workspace = terraform.workspace
  })
  config = defaults(var.config2, {
    name_prefix                = "cad-"
    availability_zone_count    = length(data.aws_availability_zones.available.names)
    public_subnet_bits         = 28
    private_subnet_bits        = 27
    flowlogs_retention_in_days = -1
    nat_mode                   = "single_nat_instance"
  })

  vpc_cidr_bits     = tonumber(regex("/(\\d+)$", local.config.vpc_cidr)[0])
  pub_sub_cidr_bits = local.config.public_subnet_bits - local.vpc_cidr_bits - [0, 1, 2, 2][local.config.availability_zone_count - 1]
  prv_sub_cidr_bits = local.config.private_subnet_bits - local.vpc_cidr_bits - [0, 1, 2, 2][local.config.availability_zone_count - 1]

  cidrs = cidrsubnets(local.config.vpc_cidr, local.pub_sub_cidr_bits, local.prv_sub_cidr_bits)

  subnet = { for net in setunion(
    [for idx in range(local.config.availability_zone_count) : {
      type              = "public"
      no                = idx
      availability_zone = data.aws_availability_zones.available.names[idx]
      cidr              = cidrsubnet(local.cidrs[0], local.config.public_subnet_bits - local.vpc_cidr_bits - local.pub_sub_cidr_bits, idx)
    }],
    [for idx in range(local.config.availability_zone_count) : {
      type              = "private"
      no                = idx
      availability_zone = data.aws_availability_zones.available.names[idx]
      cidr              = cidrsubnet(local.cidrs[1], local.config.private_subnet_bits - local.vpc_cidr_bits - local.prv_sub_cidr_bits, idx)
    }]
  ) : "${net.type}-${net.no}" => net }
}
