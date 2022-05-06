output "alb_hostname" {
  description = ""
  value       = local.enable_load_balancer > 0 ? aws_lb.this[0].dns_name : null
}

output "alb_arn" {
  description = ""
  value       = local.enable_load_balancer > 0 ? aws_lb.this[0].arn : null
}

output "alb_ecurity_group_id" {
  description = ""
  value       = local.enable_load_balancer > 0 ? aws_security_group.alb[0].id : null
}

output "iam_role_arn" {
  description = ""
  value       = aws_iam_role.this.arn
}
