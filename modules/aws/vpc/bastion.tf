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


# resource "aws_security_group_rule" "ingress_bastion" {
#   count            = var.bastion_security_group_id == "" ? 1 : 0
#   description      = "Incoming traffic to bastion"
#   type             = "ingress"
#   from_port        = var.public_ssh_port
#   to_port          = var.public_ssh_port
#   protocol         = "TCP"
#   cidr_blocks      = local.ipv4_cidr_block
#   ipv6_cidr_blocks = local.ipv6_cidr_block

#   security_group_id = local.security_group
# }

# resource "aws_security_group_rule" "egress_bastion" {
#   count       = var.bastion_security_group_id == "" ? 1 : 0
#   description = "Outgoing traffic from bastion to instances"
#   type        = "egress"
#   from_port   = "0"
#   to_port     = "65535"
#   protocol    = "-1"
#   cidr_blocks = ["0.0.0.0/0"]

#   security_group_id = local.security_group
# }

# data "aws_iam_policy_document" "bastion" {
#   statement {
#     actions = [
#       "sts:AssumeRole"
#     ]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "bastion" {
#   name                 = var.bastion_iam_role_name
#   path                 = "/"
#   assume_role_policy   = data.aws_iam_policy_document.bastion.json
# }

# data "aws_iam_policy_document" "bastion" {

#   statement {
#     actions = [

#       "kms:Encrypt",
#       "kms:Decrypt"
#     ]
#     resources = [aws_kms_key.key.arn]
#   }

# }

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.bastion.id
  instance_type = "t3.nano"
  subnet_id     = aws_subnet.this["public-0"].id
  vpc_security_group_ids = merge([aws_security_group.bastion.id],
    local.config.bastion_security_groups != null ? local.config.bastion_security_groups : []
  )
  # source_dest_check      = false

  tags = merge(local.default_tags, {
    Name = "${local.config.name_prefix}bastion"
  })

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
