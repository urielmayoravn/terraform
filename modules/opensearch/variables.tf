variable "domain_name" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "cluster_config" {
  type     = map(any)
  nullable = true
  default  = null
}

variable "domain_endpoint_options" {
  type     = map(any)
  nullable = true
  default  = null
}

variable "vpc_options" {
  type = object({
    security_group_ids = optional(list(string), [])
    subnet_ids         = optional(list(string), [])
  })
}

variable "ebs_options" {
  type = object({
    ebs_enabled = optional(bool, false)
    volume_size = optional(number)
    volume_type = optional(string)
    iops        = optional(number)
    throughput  = optional(number)
  })
  nullable = true
  default  = null
}

variable "access_policies" {
  type     = string
  nullable = true
  default  = null
}
