variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "index_file_src" {
  description = "Index.html file source"
}

variable "is_static_website" {
  description = "Flag to define if bucket shold host a static website"
  type        = bool
  default     = false
}

variable "website_configuration" {
  description = "Website specifications"
  type = object({
    index_document = string
    error_document = string
  })
  default = {
    index_document = ""
    error_document = ""
  }
}

variable "cloudfront_forward" {
  type = bool
}
