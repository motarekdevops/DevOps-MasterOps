variable "project_name" {
  description = "Name prefix used to tag all resources"
  type        = string
}

variable "bucket_suffix" {
  description = "Fixed suffix to avoid S3's global bucket-name collisions. Leave empty to auto-generate one."
  type        = string
  default     = ""
}
