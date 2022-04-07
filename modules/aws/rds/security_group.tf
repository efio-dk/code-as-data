
resource "aws_security_group" "client" {
  name        = "${local.name_prefix}client-sg"
  description = "Securitygroup for RDS clients"
  vpc_id      = local.config.vpc_id
}

resource "aws_security_group" "instance" {
  name        = "${local.name_prefix}instance-sg"
  description = "Securitygroup for RDS instances"
  vpc_id      = local.vpc_id

  ingress {
    description     = "DB TCP Port"
    from_port       = local.config.port
    to_port         = local.config.port
    protocol        = "tcp"
    security_groups = setunion([aws_security_group.client.id], local.config.client_security_groups)
    self            = true
  }

  egress {
    from_port = local.config.port
    to_port   = local.config.port
    protocol  = "tcp"
    self      = true
  }
}
