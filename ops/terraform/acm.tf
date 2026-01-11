# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-certificate"
  }
}

# Route53 Zone Data Source (if using Route53)
data "aws_route53_zone" "main" {
  count        = var.create_dns_records ? 1 : 0
  name         = var.hosted_zone_name
  private_zone = false
}

# DNS Validation Records
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_dns_records ? {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

# Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  count                   = var.create_dns_records ? 1 : 0
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
