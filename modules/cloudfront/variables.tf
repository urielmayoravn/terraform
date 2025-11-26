variable "default_origin" {
  type = string
}

variable "aliases" {
  type    = set(string)
  default = []
}

variable "create_oac" {
  type = bool
}

variable "origin_domain_name" {
  type = string
}

variable "s3_bucket" {
  type     = any
  nullable = true
  default  = null
}

variable "oac_attrs" {
  type = object({
    name             = string
    description      = optional(string)
    origin_type      = string
    signing_behavior = string
    signing_protocol = string
  })
  nullable = true
  default  = null
}

variable "default_cache_behavior" {
  type = object({
    allowed_methods        = set(string)
    cached_methods         = set(string)
    viewer_protocol_policy = string
    query_string           = bool
    cookies                = string
  })
}

variable "ordered_cache_behavior" {
  type = list(object({
    path_pattern           = string
    allowed_methods        = set(string)
    cached_methods         = set(string)
    viewer_protocol_policy = string
    query_string           = bool
    cookies                = string
  }))
}
