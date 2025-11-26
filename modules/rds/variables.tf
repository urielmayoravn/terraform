variable "environment" {
  description = "Environment"
}

variable "db_subnet_ids" {
  description = "DB subnet IDS"
  type        = list(string)
}

variable "engine" {
  description = "DB engine"
  type        = string
}

variable "engine_version" {
  description = "DB engine version"
  type        = string
}

variable "instance_class" {
  description = "DB instance class"
  type        = string
}

variable "db_name" {
  description = "DB name"
  type        = string
}

variable "db_port" {
  description = "DB port"
  type        = number
  default     = 5432
}

variable "allocated_storage" {
  description = "DB allocated storage"
  type        = number
}

variable "parameter_group_name" {
  description = "DB parameter group name"
  type        = string
}

variable "db_username" {
  description = "DB username"
  type        = string
  sensitive   = true
}

variable "security_group_ids" {
  description = "Bastion host SG"
  type        = set(string)
  default     = []
}

variable "multi_az" {
  description = "Multi AZ"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Allow final snapshot"
  type        = bool
  default     = true
}
