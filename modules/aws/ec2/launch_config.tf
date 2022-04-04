data "aws_ip_ranges" "this" {
  regions  = [data.aws_region.current.name]
  services = ["ec2_instance_connect"]
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_instance_connect_policy" {
  statement {
    actions   = ["ec2-instance-connect:SendSSHPublicKey"]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/ec2-instance-connect"
      values   = ["asg"]
    }
  }

  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"]
  }
}

resource "aws_security_group" "launch_config" {
  description = "Enable HTTP(S) access to the application load balancer."
  name        = "${local.config.name_prefix}asg"
  vpc_id      = local.vpc_id

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
    Name = "${local.config.name_prefix}asg"
  })
}

resource "aws_iam_role" "this" {
  name               = "${local.config.name_prefix}role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  inline_policy {
    name   = "ec2_instance_connect"
    policy = data.aws_iam_policy_document.ec2_instance_connect_policy.json
  }
  path = "/"
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.config.name_prefix}profile"
  role = aws_iam_role.this.name
}

resource "aws_launch_configuration" "this" {
  name_prefix                 = "${local.config.name_prefix}instance"
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
    aws_account = data.aws_caller_identity.current.account_id
    aws_region  = data.aws_region.current.name
  })

  root_block_device {
    encrypted = true

  }

  dynamic "ebs_block_device" {
    for_each = local.config.volumes

    content {
      device_name           = each.value.device_name
      delete_on_termination = true
      encrypted             = true
      # kms_key_id = 
      volume_size = each.value.size
      volume_type = each.value.type
      iops        = each.value.iops
      throughput  = each.value.throughput
      # tags = merge(local.default_tags, {
      #   instance = "${local.config.name_prefix}instance"
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
