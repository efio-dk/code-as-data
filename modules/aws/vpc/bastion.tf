# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }

# data "aws_ami" "this" {
#   most_recent = true
#   owners      = ["amazon"]
#   name_regex  = "^amzn2-ami-hvm.*-ebs"

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

# resource "aws_security_group" "this" {
#   description = "Enable SSH access to the bastion host from external via SSH port"
#   name        = "${local.config.name_prefix}-host"
#   vpc_id      = aws_vpc.this.id

#   # tags = merge(var.tags)
# }


# resource "aws_launch_configuration" "this" {
#   name_prefix   = "${local.config.name_prefix}bastion-"
#   image_id      = data.aws_ami.this.id
#   instance_type = "t3.nano"

#   iam_instance_profile =  
#   security_groups = [aws_security_group.this.id]
#   associate_public_ip_address = true
#   user_data = ""
# }

# resource "aws_autoscaling_group" "this" {
#   name                 = "${local.config.name_prefix}bastion"
#   launch_configuration = aws_launch_configuration.this.name
#   health_check_type    = "ec2"
#   min_size             = 0
#   max_size             = 1
#   desired_capacity     = 1

#   lifecycle {
#     create_before_destroy = true
#   }
# }


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


# data "aws_iam_policy_document" "assume_policy_document" {
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

# resource "aws_iam_role" "bastion_host_role" {
#   name                 = var.bastion_iam_role_name
#   path                 = "/"
#   assume_role_policy   = data.aws_iam_policy_document.assume_policy_document.json
#   permissions_boundary = var.bastion_iam_permissions_boundary
# }

# data "aws_iam_policy_document" "bastion_host_policy_document" {

#   statement {
#     actions = [
#       "s3:PutObject",
#       "s3:PutObjectAcl"
#     ]
#     resources = ["${aws_s3_bucket.bucket.arn}/logs/*"]
#   }

#   statement {
#     actions = [
#       "s3:GetObject"
#     ]
#     resources = ["${aws_s3_bucket.bucket.arn}/public-keys/*"]
#   }

#   statement {
#     actions = [
#       "s3:ListBucket"
#     ]
#     resources = [
#     aws_s3_bucket.bucket.arn]

#     condition {
#       test     = "ForAnyValue:StringEquals"
#       values   = ["public-keys/"]
#       variable = "s3:prefix"
#     }
#   }

#   statement {
#     actions = [

#       "kms:Encrypt",
#       "kms:Decrypt"
#     ]
#     resources = [aws_kms_key.key.arn]
#   }

# }

# resource "aws_iam_policy" "bastion_host_policy" {
#   name   = var.bastion_iam_policy_name
#   policy = data.aws_iam_policy_document.bastion_host_policy_document.json
# }

