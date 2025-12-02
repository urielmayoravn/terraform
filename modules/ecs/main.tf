resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = var.services

  name              = each.value.task_definition.log_group_name
  retention_in_days = each.value.task_definition.log_retention_in_days
}

resource "aws_ecs_task_definition" "tasks" {
  for_each = var.services

  family                   = each.value.task_definition.family
  network_mode             = each.value.task_definition.network_mode
  cpu                      = each.value.task_definition.cpu
  memory                   = each.value.task_definition.memory
  requires_compatibilities = each.value.task_definition.requires_compatibilities
  execution_role_arn       = each.value.task_definition.execution_role_arn
  container_definitions    = each.value.task_definition.container_definitions
}

resource "aws_ecs_service" "services" {
  for_each = var.services

  name            = each.key
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tasks[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = each.value.launch_type

  network_configuration {
    subnets          = each.value.network_configuration.subnets
    security_groups  = each.value.network_configuration.security_groups
    assign_public_ip = each.value.network_configuration.assign_public_ip
  }

  load_balancer {
    target_group_arn = each.value.load_balancer.target_group_arn
    container_name   = each.value.load_balancer.container_name
    container_port   = each.value.load_balancer.container_port
  }

  deployment_circuit_breaker {
    enable   = each.value.rollback_on_error
    rollback = each.value.rollback_on_error
  }

}
