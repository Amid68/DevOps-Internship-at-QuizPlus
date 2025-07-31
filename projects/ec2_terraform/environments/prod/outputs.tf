output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP address"
  value       = module.ec2.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address within the VPC"
  value       = module.ec2.private_ip
}

output "ec2_public_dns" {
  description = "Public DNS name for the EC2 instance"
  value       = module.ec2.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}
