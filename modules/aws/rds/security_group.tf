
resource "aws_security_group" "client" {
  name        = "${local.config.name_prefix}client-sg"
  description = "Securitygroup for RDS clients"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "instance" {
  name        = "${local.config.name_prefix}instance-sg"
  description = "Securitygroup for RDS instances"
  vpc_id      = local.vpc_id

  ingress {
    description     = "DB TCP Port"
    from_port       = local.config.port
    to_port         = local.config.port
    protocol        = "tcp"
    security_groups = [aws_security_group.client.id]
    self            = true
  }

  egress {
    from_port = local.config.port
    to_port   = local.config.port
    protocol  = "tcp"
    self      = true
  }
}
