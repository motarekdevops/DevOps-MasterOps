variable "project_name" {
  description = "Name prefix used to tag all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to launch the instance into"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID to launch the instance into"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to launch (defaults to latest Ubuntu 24.04 LTS in the region if left empty)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}
