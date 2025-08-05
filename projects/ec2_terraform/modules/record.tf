resource "aws_route53_record" "this" {
  count = var.manage_dns ? 1 : 0

  zone_id = var.create_hosted_zone ? aws_route53_zone.this[0].zone_id : var.existing_zone_id
  name = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  type = "A"
  ttl = var.dns_ttl
  records = [aws_eip.this.public_ip]

  depends_on = [aws_eip.this]
}

resource "aws_route53_record" "www" {
  count = var.manage_dns && var.create_www_records ? 1 : 0

  zone_id = var.create_hosted_zone ? aws_route53_zone.this[0].zone_id : var.existing_zone_id
  name = "www.${var.domain_name}"
  type = "CNAME"
  ttl = var.dns_ttl
  records = [var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name]

  depends_on = [aws_route53_record.this]
}
