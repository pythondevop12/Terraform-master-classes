variable "aws_region" {
    description = "aws region"
    type = string
    default = "us-east-1"
}

variable "ami_id" {
    description = "ec2 instance id"
    type = string
    default = "ami-091138d0f0d41ff90"
}

variable "instance_type" {
    description = "ec2 instance type"
    type = string
    default = "t2.micro"
}
variable "key_name" {
    description = "ssh key"
    type = string
    default = "vpc-a-keydemo"
}