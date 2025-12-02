variable "topic_name" {
  type = string
}

variable "subscriptions" {
  type = list(map(string))
}
