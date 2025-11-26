output "db_ssm_name" {
  value = aws_ssm_parameter.db_url.name
}
