resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "My DB subnet group"
  }
}

resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$"

}

resource "aws_db_instance" "default" {
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  username               = var.db_username
  password               = random_password.db_password.result
  parameter_group_name   = var.parameter_group_name
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = var.security_group_ids
  skip_final_snapshot    = var.skip_final_snapshot
  multi_az               = var.multi_az
}

resource "aws_ssm_parameter" "db_url" {
  name        = "/${var.environment}/database/connection_string"
  description = "DB connection string"
  type        = "SecureString"
  value       = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.default.endpoint}/${var.db_name}?sslmode=no-verify"
}
