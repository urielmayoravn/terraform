variable "lb_type" {
  type = string
}

variable "internal" {
  type = bool
}

variable "security_groups" {
  type = list(string)
}

variable "subnets" {
  type = list(string)
}

variable "listener_protocol" {
  type = string
}

variable "listener_port" {
  type = number
}

variable "target_grups" {
  type = map(object({
    target_type    = string
    port           = number
    vpc_id         = string
    protocol       = string
    forward_weight = number

    health_check = optional(object({
      enabled             = bool
      interval            = number
      path                = string
      port                = string
      protocol            = string
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    }))
  }))
}
