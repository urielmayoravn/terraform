resource "aws_lb" "main" {
  load_balancer_type = var.lb_type
  internal           = var.internal
  security_groups    = var.security_groups
  subnets            = var.subnets
}

resource "aws_lb_target_group" "target_groups" {
  for_each = var.target_grups

  name        = each.key
  target_type = each.value.target_type
  port        = each.value.port
  vpc_id      = each.value.vpc_id
  protocol    = each.value.protocol

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []

    content {
      enabled             = health_check.value.enabled
      interval            = health_check.value.interval
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = var.listener_protocol
  port              = var.listener_port

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = aws_lb_target_group.target_groups
        content {
          arn = target_group.value.arn
        }
      }
    }
  }
}

resource "aws_lb_listener_rule" "listener_rules" {
  for_each     = var.listener_rules
  listener_arn = aws_lb_listener.listener.arn
  priority     = each.value.priority

  action {
    type             = each.value.action.type
    target_group_arn = aws_lb_target_group.target_groups[each.key].arn
  }

  condition {
    dynamic "path_pattern" {
      for_each = each.value.condition.type == "path_pattern" ? [each.value.condition] : []
      content {
        regex_values = path_pattern.value.regex
        values       = path_pattern.value.values
      }
    }
    dynamic "host_header" {
      for_each = each.value.condition.type == "host_header" ? [each.value.condition] : []
      content {
        regex_values = host_header.value.regex
        values       = host_header.value.values
      }
    }
  }

}
