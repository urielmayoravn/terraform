locals {
  all_ips = "0.0.0.0/0"
}

module "vpc" {
  source = "../../modules/vpc"

  cidr_block = "10.2.0.0/21"
  public_subnets = [
    {
      cidr_block = "10.2.0.0/24"
      az         = "us-west-2a"
      name       = "TF-TEST-PUBLIC-SB-1"
    },
    {
      cidr_block = "10.2.1.0/24"
      az         = "us-west-2b"
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
      az         = "us-west-2b"
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


module "aws_be_lb_security_group" {
  source = "../../modules/security_group"

  name   = "backend_alb_sg"
  desc   = "Backend ALB Security Group"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [{
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_ipv4   = local.all_ips
  }]
}

module "aws_be_ecs_security_group" {
  source = "../../modules/security_group"

  name   = "backend_ecs_sg"
  desc   = "Backend ECS Security Group"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [{
    ip_protocol                  = "tcp"
    from_port                    = 3000
    to_port                      = 3000
    referenced_security_group_id = module.aws_be_lb_security_group.sg_id
  }]
}

module "rds_security_group" {
  source = "../../modules/security_group"

  name   = "fullstack_db_security_group"
  desc   = "RDS Security Group"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [{
    ip_protocol                  = "tcp"
    from_port                    = 5432
    to_port                      = 5432
    referenced_security_group_id = module.aws_be_ecs_security_group.sg_id
  }]
}

module "rds" {
  source = "../../modules/rds"

  environment          = var.environment
  security_group_ids   = [module.rds_security_group.sg_id]
  db_subnet_ids        = module.vpc.private_db_subnet_ids
  allocated_storage    = 20
  db_name              = "mydb"
  db_username          = "urielmayo"
  db_port              = 5432
  engine               = "postgres"
  engine_version       = "17.6"
  instance_class       = "db.t3.micro"
  parameter_group_name = "default.postgres17"
}

data "aws_ssm_parameter" "db_url" {
  name            = module.rds.db_ssm_name
  with_decryption = true
  depends_on      = [module.rds]
}

# module "frontend_alb" {
#   source = "../../modules/alb"

#   lb_type         = "application"
#   internal        = false
#   security_groups = [module.aws_be_lb_security_group.sg_id]
#   subnets         = module.vpc.public_subnet_ids

#   listener_protocol = "HTTP"

#   target_grups = {
#     "fe-alb-tg" = {
#       target_type    = "ip"
#       port           = 3000
#       vpc_id         = module.vpc.vpc_id
#       protocol       = "HTTP"
#       forward_weight = 100
#     }
#   }

# }

module "backend_alb" {
  source = "../../modules/alb"

  lb_type         = "application"
  internal        = false
  security_groups = [module.aws_be_lb_security_group.sg_id]
  subnets         = module.vpc.public_subnet_ids

  listener_protocol = "HTTP"
  listener_port     = 80

  target_grups = {
    "be-alb-tg" = {
      target_type    = "ip"
      port           = 80
      vpc_id         = module.vpc.vpc_id
      protocol       = "HTTP"
      forward_weight = 100

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
      }
    }
  }
}

resource "aws_ecr_repository" "backend" {
  name = "fullstack-app/backend"
}

resource "aws_ecr_repository" "frontend" {
  name = "fullstack-app/frontend"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

resource "aws_iam_role_policy_attachment" "ecs_ssm_read_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"

}

module "ecs" {

  depends_on = [
    module.backend_alb,
    aws_iam_role_policy_attachment.ecs_execution_role_policy,
    aws_iam_role_policy_attachment.ecs_ssm_read_role_policy
  ]

  source = "../../modules/ecs"

  cluster_name = "fullstack-app"

  services = {
    backend = {
      desired_count = 1
      launch_type   = "FARGATE"

      network_configuration = {
        subnets          = module.vpc.public_subnet_ids
        security_groups  = [module.aws_be_ecs_security_group.sg_id]
        assign_public_ip = true
      }

      load_balancer = {
        target_group_arn = module.backend_alb.target_groups["be-alb-tg"].arn
        container_name   = "be-container"
        container_port   = 3000
      }

      task_definition = {
        family                   = "be-task"
        network_mode             = "awsvpc"
        cpu                      = 512
        memory                   = 1024
        requires_compatibilities = ["FARGATE"]
        execution_role_arn       = aws_iam_role.ecs_execution_role.arn
        container_definitions = jsonencode(
          [
            {
              name  = "be-container"
              image = "212155079774.dkr.ecr.us-west-2.amazonaws.com/todo-app/backend:1.0.4"
              portMappings = [
                {
                  containerPort = 3000
                  protocol      = "tcp"
                }
              ],
              logConfiguration = {
                logDriver = "awslogs"
                options = {
                  awslogs-group         = "/ecs/fullstack-app/be"
                  awslogs-region        = "us-west-2"
                  awslogs-stream-prefix = "my-app"
                }
              }
              secrets = [{
                valueFrom = data.aws_ssm_parameter.db_url.arn
                name      = "DATABASE_URL",
              }]
            }
          ]
        )

        log_group_name        = "/ecs/fullstack-app/be"
        log_retention_in_days = 1
      }
    }
  }

}
