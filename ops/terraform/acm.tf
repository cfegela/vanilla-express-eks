# Locals for certificate and hosted zone
locals {
  certificate_arn  = var.acm_certificate_arn
  hosted_zone_id   = var.hosted_zone_id
}
