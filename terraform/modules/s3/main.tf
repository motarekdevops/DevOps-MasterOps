resource "random_id" "suffix" {
  count       = var.bucket_suffix == "" ? 1 : 0
  byte_length = 4
}

locals {
  suffix      = var.bucket_suffix != "" ? var.bucket_suffix : random_id.suffix[0].hex
  bucket_name = "${var.project_name}-app-${local.suffix}"
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  # Guards against 'terraform destroy' silently wiping this bucket.
  # Remove this block deliberately if you actually want to tear it down.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
