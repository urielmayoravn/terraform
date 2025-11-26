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

resource "aws_lb_listener" "listeners" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = var.listener_protocol
  port              = var.listener_port

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = aws_lb_target_group.target_groups
        content {
          arn    = target_group.value.arn
          weight = var.target_grups[target_group.value.name].forward_weight
        }
      }
    }
  }
}
