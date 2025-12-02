variable "environment" {
  description = "The environment for which the security groups are being created (e.g., dev, staging, prod)."
  type        = string
}

variable "sns_endpoint_email" {
  type      = string
  sensitive = true
}
