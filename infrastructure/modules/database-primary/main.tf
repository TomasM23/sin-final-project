resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-primary-db-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-primary-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]

  multi_az                = true
  publicly_accessible     = false
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true

  performance_insights_enabled = false
}
