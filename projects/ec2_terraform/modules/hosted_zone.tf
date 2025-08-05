resource "aws_route53_zone" "this" {
  count = var.manage_dns && var.create_hosted_zone ? 1 : 0

  name = var.domain_name
}
