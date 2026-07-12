output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_1_id" {
  value = module.vpc.public_subnet_1_id
}

output "public_subnet_2_id" {
  value = module.vpc.public_subnet_2_id
}

output "private_subnet_1_id" {
  value = module.vpc.private_subnet_1_id
}

output "private_subnet_2_id" {
  value = module.vpc.private_subnet_2_id
}

output "app_security_group_id" {
  value = module.vpc.app_security_group_id
}

output "db_security_group_id" {
  value = module.vpc.db_security_group_id
}

output "ec2_instance_id" {
  value = module.compute.instance_id
}

output "ec2_public_ip" {
  value = module.compute.public_ip
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_name" {
  value = module.database.db_name
}

output "orders_queue_url" {
  value = module.queue.queue_url
}

output "orders_queue_arn" {
  value = module.queue.queue_arn
}

output "orders_dlq_url" {
  value = module.queue.dlq_url
}