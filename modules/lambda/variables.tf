variable "filename" {
  type = string
}

variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

variable "required_role_policy_arns" {
  type    = list(string)
  default = []
}

variable "include_logging" {
  type    = bool
  default = true
}


variable "permissions" {
  type = list(object({
    statement_id = string
    principal    = string
    source_arn   = string
  }))
}

variable "environment_variables" {
  type     = map(string)
  nullable = true
  default  = null
}
