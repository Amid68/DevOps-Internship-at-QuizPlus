resource "aws_route53_record" "ameed_de" {
  zone_id = aws_route53_zone.ameed_de.zone_id
  name = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  type = "A"
  ttl = var.dns_ttl
  records = [aws_eip.proc_mon.public_ip]

  depends_on = [aws_eip.proc_mon]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.ameed_de.zone_id
  name = "www.${var.domain_name}"
  type = "CNAME"
  ttl = var.dns_ttl
  records = [var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name]

  depends_on = [aws_route53_record.ameed_de]
}
