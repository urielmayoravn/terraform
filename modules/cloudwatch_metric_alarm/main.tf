resource "aws_cloudwatch_metric_alarm" "backend_cpu" {
  alarm_name                = var.alarm_name
  comparison_operator       = var.comparison_operator
  evaluation_periods        = var.period
  metric_name               = var.metric_name
  namespace                 = var.namespace
  period                    = var.period
  statistic                 = var.statistic
  threshold                 = var.threshold
  alarm_description         = var.alarm_description
  dimensions                = var.dimensions
  alarm_actions             = var.actions.alarm
  ok_actions                = var.actions.ok
  insufficient_data_actions = var.actions.insufficient_data
}
