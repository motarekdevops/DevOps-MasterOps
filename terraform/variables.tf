variable "project_name" {
  description = "Name prefix used to tag all AWS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least 2 availability zones are required (one per public/private subnet pair)."
  }
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance. WARNING: the default (0.0.0.0/0) allows SSH from anywhere on the internet -- replace it with your own IP (e.g. \"203.0.113.5/32\") before running apply in anything beyond a quick test."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr must be a valid CIDR block, e.g. \"203.0.113.5/32\" or \"0.0.0.0/0\"."
  }
}

variable "bucket_suffix" {
  description = "Optional fixed suffix for the S3 bucket name (leave empty for an auto-generated one)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Root domain already delegated to Route53 (leave empty to skip DNS record creation)"
  type        = string
  default     = ""
}

variable "route53_record_names" {
  description = "Subdomains to point at the instance when domain_name is set (\"\" = apex, \"www\", \"api\", etc.)"
  type        = list(string)
  default     = ["", "www"]
}
