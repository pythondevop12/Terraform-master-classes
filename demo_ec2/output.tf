output "instance_id" {
    value = aws_instance.web_instance.id
}

output "instance_arn" {
    value = aws_instance.web_instance.arn
}

output "public_ip" {
    value = aws_instance.web_instance.public_ip
}

output "public_dns" {
    value = aws_instance.web_instance.public_dns
}