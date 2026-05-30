output "aws_vpc" {
    value = data.aws_vpc.default.id
  
}

output "aws_subnet" {
    value = data.aws_subnets.default_subnet.ids
}

output "instance_id" {
    value = aws_instance.web-ec2.id
}