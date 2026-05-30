# first data block for vpc

data "aws_vpc" "default" {
    filter {
        name = "tag:Name"
        values = ["default"]
    }
}

# second data block and for all subnets in default vpc

data "aws_subnets" "default_subnet" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

# third data block for ec2 ami id

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}



resource "aws_instance" "web-ec2"{
    ami = data.aws_ami.ubuntu.id
    subnet_id = data.aws_subnets.default_subnet.ids[0]
    instance_type = var.instance_type

    tags = {
        Name = "web-ec2"
        ManagedBy = "terraform"

    }
}