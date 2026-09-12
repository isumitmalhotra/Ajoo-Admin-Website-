/**
 * The certificate for the API hostname.
 *
 * DNS validation, not email: email validation needs somebody to click a link
 * in an inbox nobody may still read, and it has to be repeated on renewal.
 * DNS validation renews itself for as long as the record stays in place.
 *
 * THE RECORDS ARE NOT CREATED HERE, on purpose. Decision 3 in the migration
 * plan — whether `aajoohomes.com` moves to Route 53 or stays at the current
 * registrar — is still open, and this stack should not quietly take ownership
 * of a zone that answer might not put here. So the validation records come out
 * as an OUTPUT for somebody to add wherever the zone actually lives, and
 * `manage_dns` flips to true the day that decision lands.
 *
 * Until the record exists the certificate sits at PENDING_VALIDATION, the HTTPS
 * listener in alb.tf cannot come up, and `terraform apply` will wait on it. That
 * is the correct order: an ALB serving the wrong certificate is worse than one
 * that is not serving yet.
 */

variable "api_hostname" {
  description = "Decision 2. It resolves today and answers 404 — nothing to break."
  type        = string
  default     = "api.aajoohomes.com"
}

variable "manage_dns" {
  description = "True once the zone is in Route 53 (decision 3). Then validation is automatic."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Only read when manage_dns is true."
  type        = string
  default     = ""
}

resource "aws_acm_certificate" "api" {
  domain_name       = var.api_hostname
  validation_method = "DNS"

  lifecycle {
    # Replace before destroying: a listener cannot be left without a
    # certificate for the moments in between.
    create_before_destroy = true
  }

  tags = { Name = "${local.name}-api" }
}

resource "aws_route53_record" "api_validation" {
  for_each = var.manage_dns ? {
    for o in aws_acm_certificate.api.domain_validation_options :
    o.domain_name => { name = o.resource_record_name, type = o.resource_record_type, record = o.resource_record_value }
  } : {}

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "api" {
  count                   = var.manage_dns ? 1 : 0
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for r in aws_route53_record.api_validation : r.fqdn]
}

output "acm_validation_records" {
  description = "Add these to whichever zone serves aajoohomes.com, then the certificate issues itself."
  value = [
    for o in aws_acm_certificate.api.domain_validation_options : {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  ]
}
