resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  request_interval  = 10
  failure_threshold = 3

  tags = { Name = "primary-region-health" }
}

resource "aws_route53_record" "primary" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "primary"
  failover_routing_policy { type = "PRIMARY" }
  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.primary_alb_dns
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "standby" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "standby"
  failover_routing_policy { type = "SECONDARY" }

  alias {
    name                   = var.standby_alb_dns
    zone_id                = var.standby_alb_zone_id
    evaluate_target_health = true
  }
}
