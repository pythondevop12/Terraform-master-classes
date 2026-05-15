terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

# #0 priority -> 0

# variable "region" {
#   description = "this is for the aws region"
#   default = "us-east-1"
# }

# variable "bucket_name" {
#   description = "this is going to be the bucket name"
#   default = "pythondevops-demobucket"
# }

# provider "aws" {
#   region = var.region
# }


# resource "aws_s3_bucket" "demo_bucket" {
#     bucket = var.bucket_name
  
# }

# #1 priority -> 1

provider "aws" {
  region = var.region
}


resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.bucket_name
}