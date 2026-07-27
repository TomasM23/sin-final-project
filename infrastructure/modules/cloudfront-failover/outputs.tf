output "domain_name" {
  value = aws_cloudfront_distribution.failover.domain_name
}

output "distribution_id" {
  value = aws_cloudfront_distribution.failover.id
}