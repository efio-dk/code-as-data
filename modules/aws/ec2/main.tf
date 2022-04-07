locals {
  config = defaults(var.config, {
    ami                  = "amazon_linux_2"
    min_size             = 1
    max_size             = 1
    desired_capacity     = 1
    enable_load_balancer = true
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

  enable_load_balancer = local.enable_load_balancer ? 1 : 0
}
