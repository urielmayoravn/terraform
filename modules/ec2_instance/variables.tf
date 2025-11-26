variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID"
  type        = string
  default     = ""
}

variable "user_data_sh" {
  description = "EC2 Initial Script"
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "Bastion Host Security Group ID"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Key Pair"
  type        = string
}

variable "Name" {
  description = "EC2 Name"
  type        = string
  default     = ""
}
