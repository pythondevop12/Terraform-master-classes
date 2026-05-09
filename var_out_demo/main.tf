terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
    region = var.aws_region
}

resource "aws_s3_bucket" "demo_bucket" {
    bucket = var.bucket

    tags = {
      Env = var.environment
      Project = var.project_name
      ManagedBy = "Terraform"
    }
}