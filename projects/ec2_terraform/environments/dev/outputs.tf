output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.ec2_instance_id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.ec2_public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2.ec2_private_ip
}

output "elastic_ip" {
  description = "Elastic IP Address"
  value       = module.ec2.elastic_ip
}

output "domain_name" {
  description = "Full domain name"
  value       = module.ec2.domain_name
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.ec2.hosted_zone_id
}
