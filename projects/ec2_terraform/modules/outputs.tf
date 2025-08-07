output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.proc_mon.public_ip
}

output "domain_name" {
  description = "Full domain name"
  value       = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
}
