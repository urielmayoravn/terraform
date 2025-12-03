locals {
  all_ips = "0.0.0.0/0"
  region  = "us-west-2"
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


module "app_alb_security_group" {
  source = "../../modules/security_group"

  name   = "app_alb_sg"
  desc   = "App ALB Security Group"
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
    referenced_security_group_id = module.app_alb_security_group.sg_id
  }]
}

module "aws_fe_ecs_security_group" {
  source = "../../modules/security_group"

  name   = "frontend_ecs_sg"
  desc   = "Frontend ECS Security Group"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [{
    ip_protocol                  = "tcp"
    from_port                    = 80
    to_port                      = 80
    referenced_security_group_id = module.app_alb_security_group.sg_id
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

module "app_alb" {
  source = "../../modules/alb"

  depends_on      = [module.vpc, module.app_alb_security_group]
  lb_type         = "application"
  internal        = false
  security_groups = [module.app_alb_security_group.sg_id]
  subnets         = module.vpc.public_subnet_ids

  listener_protocol = "HTTP"
  listener_port     = 80

  target_grups = {
    "backend" = {
      target_type = "ip"
      port        = 80
      vpc_id      = module.vpc.vpc_id
      protocol    = "HTTP"

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/api/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
      }
    }
    "frontend" = {
      target_type = "ip"
      port        = 80
      vpc_id      = module.vpc.vpc_id
      protocol    = "HTTP"
    }
  }

  listener_rules = {
    "backend" = {
      priority = 10
      action = {
        type = "forward"
      }
      condition = {
        type   = "path_pattern"
        values = ["/api/*"]
      }
    }
    "frontend" = {
      priority = 20
      action = {
        type = "forward"
      }
      condition = {
        type   = "path_pattern"
        values = ["/*"]
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
    module.app_alb,
    aws_ecr_repository.backend,
    aws_ecr_repository.frontend,
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
        target_group_arn = module.app_alb.target_groups["backend"].arn
        container_name   = "be-container"
        container_port   = 3000
      }

      rollback_on_error = true

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
              image = "212155079774.dkr.ecr.us-west-2.amazonaws.com/fullstack-app/backend:1.3.7"
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
    frontend = {
      desired_count = 1
      launch_type   = "FARGATE"

      network_configuration = {
        subnets          = module.vpc.public_subnet_ids
        security_groups  = [module.aws_fe_ecs_security_group.sg_id]
        assign_public_ip = true
      }

      load_balancer = {
        target_group_arn = module.app_alb.target_groups["frontend"].arn
        container_name   = "fe-container"
        container_port   = 80
      }

      task_definition = {
        family                   = "fe-task"
        network_mode             = "awsvpc"
        cpu                      = 512
        memory                   = 1024
        requires_compatibilities = ["FARGATE"]
        execution_role_arn       = aws_iam_role.ecs_execution_role.arn
        container_definitions = jsonencode(
          [
            {
              name  = "fe-container"
              image = "212155079774.dkr.ecr.us-west-2.amazonaws.com/fullstack-app/frontend:1.1.11"
              portMappings = [
                {
                  containerPort = 80
                  protocol      = "tcp"
                }
              ],
              logConfiguration = {
                logDriver = "awslogs"
                options = {
                  awslogs-group         = "/ecs/fullstack-app/fe"
                  awslogs-region        = "us-west-2"
                  awslogs-stream-prefix = "my-app"
                }
              }
              environment = [{
                value = "http://${module.app_alb.alb.dns_name}/api"
                name  = "VITE_BACKEND_URL",
              }]
            }
          ]
        )

        log_group_name        = "/ecs/fullstack-app/fe"
        log_retention_in_days = 1
      }
    }
  }

}


module "lambda" {
  source        = "../../modules/lambda"
  filename      = "../../lambda_functions/sns_slack_message/deployment_package.zip"
  function_name = "slack_notification"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"

  permissions = [{
    statement_id = "AllowExecutionFromSNS"
    principal    = "sns.amazonaws.com"
    source_arn   = module.alarms_sns.topic.arn
  }]
  required_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"]

  environment_variables = {
    "aws_region"         = local.region
    "ssm_parameter_name" = "/devops/slack-webhook"
  }
}

module "alarms_sns" {
  source     = "../../modules/sns"
  topic_name = "fullstack-app-cloudwatch-topic"
  subscriptions = [
    {
      protocol = "email"
      endpoint = var.sns_endpoint_email
    },
    {
      protocol = "lambda"
      endpoint = module.lambda.func.arn
    }
  ]
}

module "backend_cpu_alarm" {
  source              = "../../modules/cloudwatch_metric_alarm"
  alarm_name          = "backend-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors the ecs backend service cpu utilization"
  dimensions = {
    ClusterName = module.ecs.cluster.name
    ServiceName = module.ecs.services["backend"].name
  }
  actions = {
    alarm = [module.alarms_sns.topic.arn]
    ok    = [module.alarms_sns.topic.arn]
  }
}

module "backend_memory_alarm" {
  source              = "../../modules/cloudwatch_metric_alarm"
  alarm_name          = "backend-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors the ecs backend service memory utilization"
  dimensions = {
    ClusterName = module.ecs.cluster.name
    ServiceName = module.ecs.services["backend"].name
  }
  actions = {
    alarm = [module.alarms_sns.topic.arn]
    ok    = [module.alarms_sns.topic.arn]
  }
}

module "frontend_cpu_alarm" {
  source              = "../../modules/cloudwatch_metric_alarm"
  alarm_name          = "frontend-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors the ecs frontend service cpu utilization"
  dimensions = {
    ClusterName = module.ecs.cluster.name
    ServiceName = module.ecs.services["frontend"].name
  }
  actions = {
    alarm = [module.alarms_sns.topic.arn]
    ok    = [module.alarms_sns.topic.arn]
  }
}

module "frontend_memory_alarm" {
  source              = "../../modules/cloudwatch_metric_alarm"
  alarm_name          = "frontend-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors the ecs frontend service memory utilization"
  dimensions = {
    ClusterName = module.ecs.cluster.name
    ServiceName = module.ecs.services["frontend"].name
  }
  actions = {
    alarm = [module.alarms_sns.topic.arn]
    ok    = [module.alarms_sns.topic.arn]
  }
}

module "db_cpu_alarm" {
  source              = "../../modules/cloudwatch_metric_alarm"
  alarm_name          = "db-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors the db cpu utilization"
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instnace.id
  }
  actions = {
    alarm = [module.alarms_sns.topic.arn]
    ok    = [module.alarms_sns.topic.arn]
  }
}

module "db_memory_alarm" {
  source              = "../../modules/cloudwatch_metric_alarm"
  alarm_name          = "db-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors the db memory utilization"
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instnace.id
  }
  actions = {
    alarm = [module.alarms_sns.topic.arn]
    ok    = [module.alarms_sns.topic.arn]
  }
}

module "db_storage_alarm" {
  source              = "../../modules/cloudwatch_metric_alarm"
  alarm_name          = "db-free-storage-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Minimum"
  threshold           = 20
  alarm_description   = "This alarm monitors the db free storage"
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instnace.id
  }
  actions = {
    alarm = [module.alarms_sns.topic.arn]
    ok    = [module.alarms_sns.topic.arn]
  }
}
