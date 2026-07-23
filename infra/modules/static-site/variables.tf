variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "enable_versioning" {
  description = "Whether S3 versioning should be enabled."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the static site resources."
  type        = map(string)
  default     = {}
}
