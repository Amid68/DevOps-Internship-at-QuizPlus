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

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.this.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Elastic IP allocation ID"
  value       = aws_eip.this.allocation_id
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.manage_dns && var.create_hosted_zone ? aws_route53_zone.this[0].zone_id : var.existing_zone_id
}

output "hosted_zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = var.manage_dns && var.create_hosted_zone ? aws_route53_zone.this[0].name_servers : []
}

output "domain_name" {
  description = "Full domain name"
  value       = var.manage_dns ? (var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name) : ""
}
