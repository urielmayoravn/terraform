output "cluster" {
  value = aws_ecs_cluster.main
}

output "services" {
  value = aws_ecs_service.services
}
