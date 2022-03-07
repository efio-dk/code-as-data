output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr" {
  description = "The VPC CIDR."
  value       = aws_vpc.this.cidr_block
}

output "vpc_flow_logs_loggroup" {
  description = "The VPC FlowLogs log group in CloudWatch."
  value       = local.config.flowlogs_retention_in_days < 1 ? null : aws_cloudwatch_log_group.this[0].arn
}

output "debug" {
  value = local.debug
}