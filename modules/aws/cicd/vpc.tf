data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "this" {
  count   = try(length(local.config.subnet_ids), 0) == 0 ? 1 : 0
  default = true
  state   = "available"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "this" {
  for_each = toset(data.aws_availability_zones.available.zone_ids)

  vpc_id               = data.aws_vpc.this[0].id
  availability_zone_id = each.key
  state                = "available"
  default_for_az       = true
}

resource "aws_security_group" "this" {
  name        = "${local.config.name_prefix}codebuild"
  description = "Used for ${local.config.name_prefix}codebuild projects"
  vpc_id      = data.aws_vpc.this[0].id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags, {
    Name = "${local.config.name_prefix}codebuild"
  })
}