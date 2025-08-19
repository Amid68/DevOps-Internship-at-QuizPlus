output "elastic_ip" {
  description = "Elastic IP Address"
  value       = module.ec2.elastic_ip
}

output "domain_name" {
  description = "Full domain name"
  value       = module.ec2.domain_name
}
