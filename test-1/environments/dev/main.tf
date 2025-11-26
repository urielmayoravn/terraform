module "vpc" {
  source = "../../../modules/vpc"

  cidr_block = "10.2.0.0/21"
  public_subnets = [
    {
      cidr_block = "10.2.0.0/24"
      az         = "us-west-2a"
      name       = "TF-TEST-PUBLIC-SB-1"
    },
    {
      cidr_block = "10.2.1.0/24"
      az         = "us-west-2a"
      name       = "TF-TEST-PUBLIC-SB-2"
    }
  ]
  private_subnets = [
    {
      cidr_block = "10.2.2.0/24"
      az         = "us-west-2a"
      name       = "TF-TEST-PRIVATE-SB-1"
    },
    {
      cidr_block = "10.2.3.0/24"
      az         = "us-west-2a"
      name       = "TF-TEST-PRIVATE-SB-2"
    }
  ]

  db_subnets = [
    {
      cidr_block = "10.2.4.0/24"
      az         = "us-west-2a"
      name       = "TF-TEST-DB-PRIVATE-SB-1"
    },
    {
      cidr_block = "10.2.5.0/24"
      az         = "us-west-2b"
      name       = "TF-TEST-DB_PRIVATE-SB-2"
    }
  ]
}

module "bh_sg" {
  source = "../../../modules/security_group"
  name   = "bh_security_group"
  desc   = "Bastion host security group"
  vpc_id = module.vpc.vpc_id
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

module "private_ec2_sg" {
  source = "../../../modules/security_group"
  name   = "private_security_group"
  desc   = "Private EC2 security group"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [{
    ip_protocol                  = "tcp"
    from_port                    = 22
    to_port                      = 22
    referenced_security_group_id = module.bh_sg.sg_id
  }]
  egress_rules = [{
    ip_protocol = "-1"
    cidr_ipv4   = "0.0.0.0/0"
  }]

}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key"
  public_key = file("~/.ssh/aws-key.pub")
}

module "bastion_host" {
  source             = "../../../modules/ec2_instance"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = "t2.micro"
  subnet_id          = module.vpc.public_subnet_ids["0"]
  security_group_ids = [module.bh_sg.sg_id]
  key_pair_name      = aws_key_pair.ec2_key_pair.key_name
  user_data_sh       = file("execute.sh")
  Name               = "TF-TEST-BH-EC2"
}

module "ec2_instance" {
  source             = "../../../modules/ec2_instance"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = "t2.micro"
  subnet_id          = module.vpc.private_subnet_ids["0"]
  security_group_ids = [module.private_ec2_sg.sg_id]
  key_pair_name      = aws_key_pair.ec2_key_pair.key_name
  user_data_sh       = file("execute.sh")
  depends_on         = [module.bastion_host]
  Name               = "TF-TEST-PV-EC2"
}

module "db_security_group" {
  source = "../../../modules/security_group"
  vpc_id = module.vpc.vpc_id
  name   = "db_security_group"
  desc   = "Security group dedicated for the DB"
  ingress_rules = [{
    ip_protocol                  = "tcp"
    from_port                    = 5432
    to_port                      = 5432
    referenced_security_group_id = module.private_ec2_sg.sg_id
  }]
  egress_rules = []
}

module "rds" {
  source = "../../../modules/rds"

  environment          = var.environment
  security_group_ids   = [module.db_security_group.sg_id]
  db_subnet_ids        = module.vpc.private_db_subnet_ids
  allocated_storage    = 20
  db_name              = "mydb"
  db_username          = var.db_username
  db_port              = 5432
  engine               = "postgres"
  engine_version       = "17.6"
  instance_class       = "db.t3.micro"
  parameter_group_name = "default.postgres17"
}

# module "s3" {
#   source            = "../../../modules/s3"
#   bucket_name       = "tf-test-web-bucket"
#   index_file_src    = "../../frontend/index.html"
#   is_static_website = true
#   website_configuration = {
#     index_document = "index.html"
#     error_document = "index.html"
#   }
#   cloudfront_forward = true

# }

