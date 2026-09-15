terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  azs          = var.azs
}

module "ec2" {
  source           = "./modules/ec2"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_ids[0]
  instance_type    = var.instance_type
  key_name                   = var.key_name
  allowed_ssh_cidr           = var.allowed_ssh_cidr
  iam_instance_profile_name  = module.iam.instance_profile_name
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "s3" {
  source        = "./modules/s3"
  project_name  = var.project_name
  bucket_suffix = var.bucket_suffix
}

module "route53" {
  count = var.domain_name != "" ? 1 : 0

  source             = "./modules/route53"
  domain_name        = var.domain_name
  record_names       = var.route53_record_names
  instance_public_ip = module.ec2.public_ip
}

output "s3_bucket_name" {
  description = "Name of the app S3 bucket"
  value       = module.s3.bucket_name
}

output "dns_records" {
  description = "DNS records created (empty if domain_name was not set)"
  value       = var.domain_name != "" ? module.route53[0].record_fqdns : []
}
