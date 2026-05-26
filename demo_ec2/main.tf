terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.0"
        }
    }
}



# provider block -> aws
provider "aws" {
    region = var.aws_region
}


#security group

resource "aws_security_group" "web_sg" {
    name = "web-sg"
    description = "allow ssh and http"

    ingress {
        description = "allow ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks =  ["0.0.0.0/0"]
    }

    ingress {
        description = "allow http"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks =  ["0.0.0.0/0"]
    }

    egress {
        description = "allow all traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks =  ["0.0.0.0/0"]
    }

    tags = {
        Name = "web-sg"
        ManagedBy = "terraform"
    }
}


# ec2 instance 

resource "aws_instance" "web_instance" {
    ami = var.ami_id
    key_name = var.key_name
    instance_type = var.instance_type
    user_data = file("${path.module}/userdata.sh")
    vpc_security_group_ids = [aws_security_group.web_sg.id]

    tags = {
        Name = "web-server"
        ManagedBy = "terraform"
    }
}