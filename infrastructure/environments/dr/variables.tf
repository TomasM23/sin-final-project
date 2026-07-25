variable "project_name" {
  type    = string
  default = "sin-final-project"
}

variable "primary_region" {
  type    = string
  default = "eu-west-1"
}

variable "standby_region" {
  type    = string
  default = "eu-central-1"
}

variable "primary_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "standby_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name_primary" {
  description = "Existing EC2 key pair in the primary region. Leave empty to disable SSH key assignment."
  type        = string
  default     = ""
}

variable "key_name_standby" {
  description = "Existing EC2 key pair in the standby region. Leave empty to disable SSH key assignment."
  type        = string
  default     = ""
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH. Use your public IP/32; do not use 0.0.0.0/0 in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "dockerhub_username" {
  description = "Docker Hub user containing catalog-service, order-service and notification-service images."
  type        = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "db_username" {
  type    = string
  default = "shopadmin"
}

variable "db_name" {
  type    = string
  default = "shopdb"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "enable_cross_region_read_replica" {
  description = "Creates a PostgreSQL cross-region read replica. This increases cost."
  type        = bool
  default     = true
}

variable "hosted_zone_id" {
  description = "Route 53 public hosted zone ID. Leave empty to create infrastructure without DNS failover."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Failover FQDN, for example app.example.com. Required when hosted_zone_id is set."
  type        = string
  default     = ""
}

variable "create_github_oidc" {
  type    = bool
  default = false
}

variable "github_repository" {
  description = "GitHub repository in owner/repo format."
  type        = string
  default     = ""
}
