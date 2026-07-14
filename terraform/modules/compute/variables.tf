variable "project_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "iam_instance_profile" {
  type = string
}