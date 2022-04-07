output "hostname" {
  value = aws_db_instance.this.endpoint
}

output "port" {
  value = aws_db_instance.this.port
}

output "username" {
  value = aws_db_instance.this.username
}

output "password_ssm_key" {
  value = aws_ssm_parameter.this.name
}