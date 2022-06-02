resource "aws_security_group" "master" {
  name        = "${local.name_prefix}eks-master"
  description = "SG for the ${local.name_prefix}eks Master"
  vpc_id      = local.config.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}eks-master-sg"
  })
}

resource "aws_security_group_rule" "master-ingress-https-sg" {
  type              = "ingress"
  description       = "Allow cluster API communication"
  security_group_id = aws_security_group.master.id
  cidr_blocks       = local.config.api_allowed_ips
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
}
