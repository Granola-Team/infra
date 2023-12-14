resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
      Name = var.domain_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "zone" {
  name = var.domain_name

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "cdn-alias" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "${var.domain_name}"
  type    = "A"
  alias {
    name = aws_cloudfront_distribution.dist.domain_name
    zone_id = aws_cloudfront_distribution.dist.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name      = dvo.resource_record_name
      record    = dvo.resource_record_value
      type      = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = "2h"
  }
}
