locals {
  common_tags = {
    Project     = "sin-final-project"
    Environment = "dev"
    Owner       = "team"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name

  vpc_cidr              = "10.0.0.0/16"
  public_subnet_1_cidr  = "10.0.1.0/24"
  public_subnet_2_cidr  = "10.0.2.0/24"
  private_subnet_1_cidr = "10.0.10.0/24"
  private_subnet_2_cidr = "10.0.20.0/24"

  availability_zone_1 = "eu-west-1a"
  availability_zone_2 = "eu-west-1b"

  tags = local.common_tags
}

module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  ami_id                = "ami-0c1c30571d2dae5c9"
  instance_type         = "t3.micro"
  public_subnet_id      = module.vpc.public_subnet_1_id
  app_security_group_id = module.vpc.app_security_group_id
  key_name              = "sin-final-project-key"

  tags = local.common_tags
}

module "database" {
  source = "./modules/database"

  project_name         = var.project_name
  private_subnet_1_id  = module.vpc.private_subnet_1_id
  private_subnet_2_id  = module.vpc.private_subnet_2_id
  db_security_group_id = module.vpc.db_security_group_id

  db_username = var.db_username
  db_password = var.db_password

  tags = local.common_tags
}

module "queue" {
  source = "./modules/queue"

  project_name = var.project_name

  tags = local.common_tags
}