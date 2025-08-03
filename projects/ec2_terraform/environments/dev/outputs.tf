# modules/outputs.tf
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}
