output "db_ssm_name" {
  value = aws_ssm_parameter.db_url.name
}

output "db_instnace" {
  value = aws_db_instance.default
}
