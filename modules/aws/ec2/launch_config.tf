data "aws_ip_ranges" "this" {
  regions  = [local.region_name]
  services = ["ec2_instance_connect"]
}

resource "aws_security_group" "launch_config" {
  description = "Enable HTTP(S) access to the application load balancer."
  name        = "${local.name_prefix}asg"
  vpc_id      = local.config.vpc_id

  ingress {
    description = "Allow ingress SSH from ec2 instance connect."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = data.aws_ip_ranges.this.cidr_blocks
  }

  ingress {
    description     = "Allow ingress HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [for sg in aws_security_group.alb : sg.id]
  }

  ingress {
    description     = "Allow ingress HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [for sg in aws_security_group.alb : sg.id]
  }

  ingress {
    description     = "Allow ingress HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [for sg in aws_security_group.alb : sg.id]
  }

  egress {
    description      = "Allow all egress traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}asg"
  })
}

resource "aws_launch_configuration" "this" {
  name_prefix                 = "${local.name_prefix}instance"
  image_id                    = data.aws_ami.this[local.config.ami].id
  instance_type               = local.config.instance_type
  iam_instance_profile        = aws_iam_instance_profile.this.id
  associate_public_ip_address = false
  enable_monitoring           = true
  security_groups = setunion(local.config.security_groups, [
    aws_security_group.launch_config.id
  ])
  # ebs_optimized - (Optional) If true, the launched EC2 instance will be EBS-optimized.

  user_data = templatefile("${path.module}/userdata/${local.ami[local.config.ami].userdata}", {
    ssh_keys    = local.config.trusted_ssh_public_keys
    aws_account = local.account_id
    aws_region  = local.region_name
    volumes     = local.config.volumes
    commands    = local.config.init_commands
  })

  root_block_device {
    encrypted = true
  }

  dynamic "ebs_block_device" {
    for_each = local.config.volumes

    content {
      device_name           = ebs_block_device.value.device_name
      delete_on_termination = true
      encrypted             = true
      # kms_key_id = 
      volume_size = ebs_block_device.value.size
      volume_type = ebs_block_device.value.type
      iops        = ebs_block_device.value.iops
      throughput  = ebs_block_device.value.throughput
      # tags = merge(local.default_tags, {
      #   instance = "${local.name_prefix}instance"
      # })
    }
  }

  # metadata_options {
  #   http_endpoint = "enabled"
  #   http_tokens   = "required"
  # }

  lifecycle {
    create_before_destroy = true
  }
}
