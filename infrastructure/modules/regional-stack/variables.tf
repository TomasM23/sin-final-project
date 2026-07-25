variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "admin_cidr" {
  type = string
}

variable "dockerhub_username" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "db_secret_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "create_database" {
  type    = bool
  default = false
}