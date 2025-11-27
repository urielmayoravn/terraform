output "target_groups" {
  value = aws_lb_target_group.target_groups
}

output "alb" {
  value = aws_lb.main
}
