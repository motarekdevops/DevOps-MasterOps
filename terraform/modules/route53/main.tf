# Assumes the domain's hosted zone already exists in Route53 (i.e. the
# domain is already delegated here). Fails clearly at plan time if not.
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  for_each = toset(var.record_names)

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value == "" ? var.domain_name : "${each.value}.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.instance_public_ip]
}
