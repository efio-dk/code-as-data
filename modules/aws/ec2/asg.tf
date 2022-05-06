
resource "aws_autoscaling_group" "this" {
  name                 = "${local.name_prefix}asg"
  launch_configuration = aws_launch_configuration.this.name
  min_size             = local.config.min_size
  max_size             = local.config.max_size
  desired_capacity     = local.config.desired_capacity
  vpc_zone_identifier  = local.config.private_subnets
  target_group_arns    = [for tg in aws_lb_target_group.this : tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300
  max_instance_lifetime     = 60 * 60 * 24 * 4
  termination_policies      = ["OldestInstance"]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  dynamic "tag" {
    for_each = merge(local.default_tags, {
      Name                 = "${local.name_prefix}asg-instance",
      ec2-instance-connect = "asg"
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
