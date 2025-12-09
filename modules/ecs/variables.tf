variable "cluster_name" {
  type = string
}

variable "services" {
  type = map(object({
    desired_count = number
    launch_type   = string

    create_ecr_repository = optional(bool, false)
    ecr_repository_name   = optional(string)

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
      task_role_arn            = optional(string)
      execution_role_arn       = string
      container_definitions    = string
      log_group_name           = optional(string)
      log_retention_in_days    = optional(number)
    })

    load_balancer = object({
      target_group_arn = string
      container_name   = string
      container_port   = string
    })

    autoscaling = optional(object({
      min_capacity = number
      max_capacity = number
      policies = map(object({
        type = string
        conf = object({
          adjustment_type         = optional(string)
          metric_aggregation_type = optional(string)
          cooldown                = optional(number)

          step_adjustment = optional(list(object({
            scaling_adjustment          = number
            metric_interval_lower_bound = optional(number)
            metric_interval_upper_bound = optional(number)
          })))

          metric_type        = optional(string)
          target_value       = optional(number)
          scale_in_cooldown  = optional(number)
          scale_out_cooldown = optional(number)
          resource_label     = optional(string)
        })
      }))
    }))

    rollback_on_error = optional(bool, false)

  }))

}
