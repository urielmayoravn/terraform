locals {
  metrics = {
    cpu = "ECSServiceAverageCPUUtilization"
    mem = "ECSServiceAverageMemoryUtilization"
  }

  metric_map = flatten([
    for svc_name, svc in var.services : [
      for policy_key, policy in svc.autoscaling.policies : {
        service_name = svc_name
        policy_name  = policy_key
        policy       = policy
      }
    ] if lookup(svc, "autoscaling", null) != null
  ])

}

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
  task_role_arn            = lookup(each.value.task_definition, "task_role_arn", null)
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

resource "aws_appautoscaling_target" "app_as_target" {
  for_each = {
    for svc_name, svc in var.services : svc_name => svc
    if lookup(svc, "autoscaling", null) != null
  }
  max_capacity       = each.value.autoscaling.max_capacity
  min_capacity       = each.value.autoscaling.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "app_as_policy" {
  for_each = tomap({ for svc in local.metric_map : "${svc.service_name}.${svc.policy_name}" => svc })

  name               = "${each.key}-scaling-policy"
  policy_type        = each.value.policy.type
  resource_id        = aws_appautoscaling_target.app_as_target[each.value.service_name].resource_id
  scalable_dimension = aws_appautoscaling_target.app_as_target[each.value.service_name].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app_as_target[each.value.service_name].service_namespace

  dynamic "step_scaling_policy_configuration" {
    for_each = each.value.policy.type == "StepScaling" ? [each.value.policy.conf] : []
    content {
      adjustment_type         = step_scaling_policy_configuration.value.adjustment_type
      cooldown                = lookup(step_scaling_policy_configuration.value, "cooldown", 300)
      metric_aggregation_type = lookup(step_scaling_policy_configuration.value, "metric_aggregation_type", "Average")

      dynamic "step_adjustment" {
        # Check if the step_adjustment attribute exists and treat it as a list/set
        for_each = flatten([lookup(step_scaling_policy_configuration.value, "step_adjustment", [])])
        content {
          metric_interval_lower_bound = lookup(step_adjustment.value, "metric_interval_lower_bound", null)
          metric_interval_upper_bound = lookup(step_adjustment.value, "metric_interval_upper_bound", null)
          scaling_adjustment          = step_adjustment.value.scaling_adjustment
        }
      }
    }
  }

  dynamic "target_tracking_scaling_policy_configuration" {
    for_each = each.value.policy.type == "TargetTrackingScaling" ? [each.value.policy.conf] : []
    content {
      predefined_metric_specification {
        predefined_metric_type = local.metrics[target_tracking_scaling_policy_configuration.value.metric_type]
        resource_label         = lookup(target_tracking_scaling_policy_configuration.value, "resource_label", null)
      }
      target_value       = target_tracking_scaling_policy_configuration.value.target_value
      scale_in_cooldown  = lookup(target_tracking_scaling_policy_configuration.value, "scale_in_cooldown", 300)
      scale_out_cooldown = lookup(target_tracking_scaling_policy_configuration.value, "scale_out_cooldown", 300)
    }
  }
}

