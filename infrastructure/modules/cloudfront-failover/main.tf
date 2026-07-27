resource "aws_cloudfront_distribution" "failover" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} multi-region failover"

  origin {
    domain_name = var.primary_alb_dns
    origin_id   = "primary-alb"

    connection_attempts = 1
    connection_timeout  = 3

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 5
    }
  }

  origin {
    domain_name = var.standby_alb_dns
    origin_id   = "standby-alb"

    connection_attempts = 1
    connection_timeout  = 3

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 5
    }
  }

  origin_group {
    origin_id = "dr-origin-group"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = "primary-alb"
    }

    member {
      origin_id = "standby-alb"
    }
  }

  default_cache_behavior {
    target_origin_id       = "dr-origin-group"
    viewer_protocol_policy = "allow-all"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]

    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }

      headers = ["*"]
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    DRPattern = "cloudfront-origin-failover"
  }
}