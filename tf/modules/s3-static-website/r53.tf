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

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
      Name = var.domain_name
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}
