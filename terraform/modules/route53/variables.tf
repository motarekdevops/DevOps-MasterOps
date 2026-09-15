variable "domain_name" {
  description = "Root domain already registered and delegated to Route53 (e.g. example.com)"
  type        = string
}

variable "record_names" {
  description = "Subdomains to point at the instance. Use \"\" for the apex domain, \"www\" for www, \"api\" for api.example.com."
  type        = list(string)
  default     = ["", "www"]
}

variable "instance_public_ip" {
  description = "Public IP of the EC2 instance to point DNS records at"
  type        = string
}
