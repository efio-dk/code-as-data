data "aws_ami" "this" {
  for_each = local.ami

  most_recent = true
  owners      = [each.value.owner]

  filter {
    name   = "name"
    values = [each.value.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
