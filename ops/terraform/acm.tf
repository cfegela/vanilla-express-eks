# Locals for certificate and hosted zone
locals {
  use_existing_certificate = var.acm_certificate_arn != ""
  certificate_arn          = local.use_existing_certificate ? var.acm_certificate_arn : aws_acm_certificate.main[0].arn

  use_existing_zone_id = var.hosted_zone_id != ""
  hosted_zone_id       = local.use_existing_zone_id ? var.hosted_zone_id : try(data.aws_route53_zone.main[0].zone_id, "")
}

# ACM Certificate (only created if no existing certificate ARN is provided)
resource "aws_acm_certificate" "main" {
  count             = local.use_existing_certificate ? 0 : 1
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

# Route53 Zone Data Source (only if zone ID not provided and DNS records needed)
data "aws_route53_zone" "main" {
  count        = var.create_dns_records && !local.use_existing_zone_id ? 1 : 0
  name         = var.hosted_zone_name
  private_zone = false
}

# DNS Validation Records (only created when creating a new certificate with Route53)
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_dns_records && !local.use_existing_certificate ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
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
  zone_id         = local.hosted_zone_id
}

# Certificate Validation (only when creating a new certificate)
resource "aws_acm_certificate_validation" "main" {
  count                   = var.create_dns_records && !local.use_existing_certificate ? 1 : 0
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
