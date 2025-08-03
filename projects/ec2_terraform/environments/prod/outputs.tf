output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.aws_instance.this.id
}

output "ec2_public_ip" {
  description = "Public IP address"
  value       = module.ec2.aws_instance.this.public_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.security_group.aws_security_group.ec2.id
}
