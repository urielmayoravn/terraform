variable "alarm_name" {
  type = string
}

variable "comparison_operator" {
  type = string
}

variable "evaluation_periods" {
  type = number
}

variable "metric_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "period" {
  type = number
}

variable "statistic" {
  type = string
}

variable "threshold" {
  type = number
}

variable "alarm_description" {
  type = string
}

variable "dimensions" {
  type = map(string)
}

variable "actions" {
  type = object({
    alarm             = optional(list(string), [])
    ok                = optional(list(string), [])
    insufficient_data = optional(list(string), [])
  })
  nullable = true
  default  = null
}
