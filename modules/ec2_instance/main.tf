locals {
  all_ips     = "0.0.0.0/0"
  name_prefix = "TF-TEST"
}

resource "aws_instance" "main" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = var.subnet_id
  security_groups = var.security_group_ids
  key_name        = var.key_pair_name
  tags            = { "Name" = var.Name }
  user_data       = var.user_data_sh
}
