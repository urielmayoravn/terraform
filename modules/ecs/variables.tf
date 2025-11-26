variable "cluster_name" {
  type = string
}

variable "services" {
  type = map(object({
    desired_count = number
    launch_type   = string

    network_configuration = object({
      subnets          = list(string)
      security_groups  = list(string)
      assign_public_ip = bool
    })

    task_definition = object({
      family                   = string
      network_mode             = string
      cpu                      = number
      memory                   = number
      requires_compatibilities = list(string)
      execution_role_arn       = string
      container_definitions    = string
      log_group_name           = string
      log_retention_in_days    = number
    })

    load_balancer = object({
      target_group_arn = string
      container_name   = string
      container_port   = string
    })

  }))

}
