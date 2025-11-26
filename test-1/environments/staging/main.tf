data "terraform_remote_state" "dev" {
  backend = "s3"
  config = {
    bucket = "urielmayo-terraform-state"
    key    = "dev/state"
    region = "us-west-2"
  }
}

module "ec2_sg" {
  source = "../../modules/security_group"
  name   = "staging_ec2_security_group"
  desc   = "Staging EC2 security group"
  vpc_id = data.terraform_remote_state.dev.outputs.vpc_vpc_id
  ingress_rules = [{
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_ipv4   = "0.0.0.0/0"
  }]
  egress_rules = [{
    ip_protocol = "-1"
    cidr_ipv4   = "0.0.0.0/0"
  }]
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key"
  public_key = file("~/.ssh/ec2-gb-key.pub")
}

module "ec2_instance" {
  source             = "../../modules/ec2_instance"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = "t2.micro"
  subnet_id          = data.terraform_remote_state.dev.outputs.vpc_public_subnet_ids["0"]
  security_group_ids = [module.ec2_sg.sg_id]
  key_pair_name      = aws_key_pair.ec2_key_pair.key_name
  user_data_sh       = file("execute.sh")
  Name               = "TF-STAGING-PB-EC2"
}
