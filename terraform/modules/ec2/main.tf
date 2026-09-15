# Canonical publishes the current Ubuntu AMI ID as an SSM parameter that
# never changes path/format -- this is far more stable than filtering on
# the AMI name, which Canonical has changed before (hvm-ssd -> hvm-ssd-gp3).
data "aws_ssm_parameter" "ubuntu" {
  count = var.ami_id == "" ? 1 : 0
  name  = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.ubuntu[0].value
}

# Fails early with a clear error if the key pair name doesn't exist in
# this region, instead of a confusing failure deep into 'apply'.
data "aws_key_pair" "selected" {
  key_name = var.key_name
}

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for ${var.project_name} EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

resource "aws_instance" "this" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = data.aws_key_pair.selected.key_name
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = var.iam_instance_profile_name != "" ? var.iam_instance_profile_name : null

  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-instance"
  }
}
