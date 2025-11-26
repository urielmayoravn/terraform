variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "name" {
  description = "Security group name"
  type        = string
}

variable "desc" {
  description = "Security group description"
  type        = string
}

variable "ingress_rules" {
  description = "Ingress rules"
  type = list(object({
    ip_protocol                  = string
    from_port                    = number
    to_port                      = number
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
}

variable "egress_rules" {
  description = "Egress rules"
  type = list(object({
    ip_protocol = string
    from_port   = optional(number)
    to_port     = optional(number)
    cidr_ipv4   = string
  }))
  default = [{
    ip_protocol = "-1"
    cidr_ipv4   = "0.0.0.0/0"
  }]
}
