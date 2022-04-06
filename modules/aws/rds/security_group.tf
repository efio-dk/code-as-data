
resource "aws_security_group" "client" {
  name        = "${var.name_prefix}client-sg"
  description = "Securitygroup for RDS clients"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group" "instance" {
  name        = "${var.name_prefix}instance-sg"
  description = "Securitygroup for RDS instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "DB TCP Port"
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.client.id]
    self            = true
  }

  egress {
    from_port = local.db_port
    to_port   = local.db_port
    protocol  = "tcp"
    self      = true
  }
}
