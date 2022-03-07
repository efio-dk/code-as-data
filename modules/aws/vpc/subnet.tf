resource "aws_subnet" "this" {
  for_each = local.subnet

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge(local.default_tags, {
    Name = "${local.config.name_prefix}${each.key}",
    Type = each.value.type,
  })
}
