output "instance_profile_name" {
  description = "Name of the IAM instance profile to attach to the EC2 instance"
  value       = aws_iam_instance_profile.this.name
}

output "role_name" {
  description = "Name of the EC2 IAM role (attach additional policies here as needed)"
  value       = aws_iam_role.ec2_role.name
}

output "role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}
