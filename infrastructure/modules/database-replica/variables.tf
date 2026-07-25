variable "project_name" { type = string }
variable "source_db_arn" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "db_security_group_id" { type = string }
variable "db_instance_class" { type = string }
