locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    DRPattern = "warm-standby"
  }
}

resource "random_password" "database" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-=?@^_"
}

module "primary" {
  source = "../../modules/regional-stack"

  providers = { aws = aws.primary }

  project_name       = var.project_name
  environment        = "primary"
  vpc_cidr           = var.primary_vpc_cidr
  instance_type      = var.instance_type
  key_name           = var.key_name_primary
  admin_cidr         = var.admin_cidr
  dockerhub_username = var.dockerhub_username
  image_tag          = var.image_tag
  db_secret_name     = "${var.project_name}/primary/database"
  db_username        = var.db_username
  db_password        = random_password.database.result
  db_name            = var.db_name
  create_database    = false
}

module "primary_database" {
  source = "../../modules/database-primary"

  providers = { aws = aws.primary }

  project_name         = var.project_name
  private_subnet_ids   = module.primary.private_subnet_ids
  db_security_group_id = module.primary.db_security_group_id
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = random_password.database.result
  db_instance_class    = var.db_instance_class
}

resource "aws_secretsmanager_secret" "primary_database" {
  provider = aws.primary
  name     = "${var.project_name}/primary/database"
}

resource "aws_secretsmanager_secret_version" "primary_database" {
  provider  = aws.primary
  secret_id = aws_secretsmanager_secret.primary_database.id
  secret_string = jsonencode({
    host     = module.primary_database.address
    port     = 5432
    database = var.db_name
    username = var.db_username
    password = random_password.database.result
  })
}

module "standby" {
  source = "../../modules/regional-stack"

  providers = { aws = aws.standby }

  project_name       = var.project_name
  environment        = "standby"
  vpc_cidr           = var.standby_vpc_cidr
  instance_type      = var.instance_type
  key_name           = var.key_name_standby
  admin_cidr         = var.admin_cidr
  dockerhub_username = var.dockerhub_username
  image_tag          = var.image_tag
  db_secret_name     = "${var.project_name}/standby/database"
  db_username        = var.db_username
  db_password        = random_password.database.result
  db_name            = var.db_name
  create_database    = false
}

module "standby_database" {
  count  = var.enable_cross_region_read_replica ? 1 : 0
  source = "../../modules/database-replica"

  providers = { aws = aws.standby }

  project_name         = var.project_name
  source_db_arn        = module.primary_database.arn
  private_subnet_ids   = module.standby.private_subnet_ids
  db_security_group_id = module.standby.db_security_group_id
  db_instance_class    = var.db_instance_class
}

resource "aws_secretsmanager_secret" "standby_database" {
  provider = aws.standby
  name     = "${var.project_name}/standby/database"
}

resource "aws_secretsmanager_secret_version" "standby_database" {
  provider  = aws.standby
  secret_id = aws_secretsmanager_secret.standby_database.id
  secret_string = jsonencode({
    host     = var.enable_cross_region_read_replica ? module.standby_database[0].address : module.primary_database.address
    port     = 5432
    database = var.db_name
    username = var.db_username
    password = random_password.database.result
    readonly = var.enable_cross_region_read_replica
  })
}

module "failover_dns" {
  count  = var.hosted_zone_id != "" && var.domain_name != "" ? 1 : 0
  source = "../../modules/failover-dns"

  providers = { aws = aws.primary }

  hosted_zone_id      = var.hosted_zone_id
  domain_name         = var.domain_name
  primary_alb_dns     = module.primary.alb_dns_name
  primary_alb_zone_id = module.primary.alb_zone_id
  standby_alb_dns     = module.standby.alb_dns_name
  standby_alb_zone_id = module.standby.alb_zone_id
}

module "github_oidc" {
  count  = var.create_github_oidc && var.github_repository != "" ? 1 : 0
  source = "../../modules/github-oidc"

  providers = { aws = aws.primary }

  project_name      = var.project_name
  github_repository = var.github_repository
}
module "cloudfront_failover" {
  source = "../../modules/cloudfront-failover"

  project_name    = var.project_name
  primary_alb_dns = module.primary.alb_dns_name
  standby_alb_dns = module.standby.alb_dns_name
}