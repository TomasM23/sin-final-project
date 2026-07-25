resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-standby-db-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_kms_key" "replica" {
  description             = "KMS key for cross-region RDS read replica"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-standby-postgres"

  replicate_source_db = var.source_db_arn
  instance_class      = var.db_instance_class

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.replica.arn

  backup_retention_period = 7
  skip_final_snapshot     = true
  apply_immediately       = true
}
