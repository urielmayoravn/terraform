variable "environment" {
  description = "The environment for which the security groups are being created (e.g., dev, staging, prod)."
  type        = string
}

variable "db_username" {
  description = "DB USERNAME"
  type        = string
}
