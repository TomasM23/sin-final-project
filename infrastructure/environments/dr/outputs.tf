output "primary" {
  value = {
    region      = var.primary_region
    instance_id = module.primary.instance_id
    public_ip   = module.primary.public_ip
    alb_dns     = module.primary.alb_dns_name
    queue_url   = module.primary.queue_url
    db_endpoint = module.primary_database.address
  }
}

output "standby" {
  value = {
    region      = var.standby_region
    instance_id = module.standby.instance_id
    public_ip   = module.standby.public_ip
    alb_dns     = module.standby.alb_dns_name
    queue_url   = module.standby.queue_url
    db_endpoint = var.enable_cross_region_read_replica ? module.standby_database[0].address : null
  }
}

output "failover_fqdn" {
  value = var.hosted_zone_id != "" && var.domain_name != "" ? var.domain_name : null
}

output "github_actions_role_arn" {
  value = var.create_github_oidc && var.github_repository != "" ? module.github_oidc[0].role_arn : null
}

output "database_password" {
  value     = random_password.database.result
  sensitive = true
}
output "dr_cloudfront_domain" {
  description = "Single public endpoint with automatic regional failover"
  value       = module.cloudfront_failover.domain_name
}

output "dr_cloudfront_distribution_id" {
  description = "CloudFront distribution identifier"
  value       = module.cloudfront_failover.distribution_id
}
