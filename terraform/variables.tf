variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "project_name" {
  type    = string
  default = "sin-final-project"
}

variable "db_username" {
  type    = string
  default = "shopadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}