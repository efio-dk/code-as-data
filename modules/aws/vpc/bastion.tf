data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^amzn2-ami-hvm.*-ebs"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "bastion" {
  description = "Enable SSH access to the bastion host from external via SSH port"
  name        = "${local.config.name_prefix}-host"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow ingress traffic from the VPC CIDR block"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.config.trusted_ip_cidrs
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
    Name = "${local.config.name_prefix}bastion"
  })
}

data "aws_iam_policy_document" "bastion" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${local.config.name_prefix}bastion-role"
  assume_role_policy = data.aws_iam_policy_document.bastion.json
  path               = "/"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.config.name_prefix}bastion-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.bastion.id
  instance_type = "t3.nano"
  subnet_id     = aws_subnet.this["public-0"].id
  iam_instance_profile = aws_iam_instance_profile.bastion.id
  vpc_security_group_ids = setunion([aws_security_group.bastion.id],
    local.config.bastion_security_groups
  )
  # source_dest_check      = false
  key_name = "dimh-jr"

  tags = merge(local.default_tags, {
    Name = "${local.config.name_prefix}bastion"
  })

user_data =   templatefile("${path.module}/bastion_userdata.sh", {ssh_keys = local.trusted_ssh_public_keys})

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "bastion" {
  vpc = true
  tags = merge(local.default_tags, {
    Name = "${local.config.name_prefix}bastion"
    Type = "public"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}
