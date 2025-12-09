output "cluster" {
  value = aws_ecs_cluster.main
}

output "services" {
  value = aws_ecs_service.services
}

output "scaling_policies" {
  value = aws_appautoscaling_policy.app_as_policy
}
