terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "s3"
  region = var.region
}

resource "aws_s3_bucket" "this" {
  bucket = var.name

  provider = aws.s3

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "Production"
    Name        = "Terraform State Bucket"
    Project     = var.project
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  provider = aws.s3

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  provider = aws.s3

  rule {
    id = "Maximum retention for Terraform state"

    filter {
      prefix = "state/"
    }

    noncurrent_version_expiration {
      newer_noncurrent_versions = 25
      noncurrent_days           = 1
    }

    status = "Enabled"
  }

  rule {
    id = "Maximum retention for Terraform plans"

    filter {
      prefix = "state/"
    }

    noncurrent_version_expiration {
      newer_noncurrent_versions = 1
      noncurrent_days           = 1
    }

    status = "Enabled"
  }

  rule {
    id = "TTL for Terraform plans"

    filter {
      prefix = "plans/"
    }

    expiration {
      days = 14
    }

    status = "Enabled"
  }

  rule {
    id = "Delete dangling delete markers"

    expiration {
      expired_object_delete_marker = true
    }

    status = "Enabled"
  }
}
