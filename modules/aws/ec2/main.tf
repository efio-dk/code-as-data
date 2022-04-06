data "aws_subnet" "alb" {
  for_each = setunion(local.config.public_subnets, local.config.private_subnets)

  id = each.value
}

locals {
  config = defaults(var.config, {
    ami              = "amazon_linux_2"
    min_size         = 1
    max_size         = 1
    desired_capacity = 1
  })

  ami = {
    amazon_linux_2 = {
      owner    = "amazon"
      name     = "amzn2-ami-hvm-*-x86_64-ebs"
      userdata = "amazon_linux.sh"
    }
    amazon_linux_ecs = {
      owner    = "amazon"
      name     = "amzn-ami-*-amazon-ecs-optimized"
      userdata = "amazon_linux.sh"
    }
    ubuntu = {
      owner    = "099720109477" # Canonical
      name     = "ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"
      userdata = "ubuntu.sh"
    }
  }

  vpc_id               = one(distinct([for subnet in data.aws_subnet.alb : subnet.vpc_id]))
  enable_load_balancer = local.config.public_subnets != null && length(local.config.public_subnets) > 0 ? 1 : 0
}
