variable "cidr_block" {
  description = "The name of the project to which the VPC belongs."
  type        = string
}

variable "public_subnets" {
  description = "CIDRs of public subnets"
  type = list(object({
    cidr_block = string
    az         = string
    name       = optional(string)
  }))
  default = []
}

variable "private_subnets" {
  description = "CIDRs of private subnets"
  type = list(object({
    cidr_block = string
    az         = string
    name       = optional(string)
  }))
  default = []
}

variable "db_subnets" {
  description = "CIDRs of private db subnets"
  type = list(object({
    cidr_block = string
    az         = string
    name       = optional(string)
  }))
  default = []
}


