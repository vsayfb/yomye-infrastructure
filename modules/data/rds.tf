locals {
  name_prefix = var.name_prefix

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "data"
    }
  )
}

resource "random_string" "db_username_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

locals {
  db_master_username = "${local.name_prefix}_${random_string.db_username_suffix.result}"
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-subnet-group"
  })
}

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = var.db_storage_type
  storage_encrypted = var.db_storage_encrypted

  db_name  = var.db_name
  username = local.db_master_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  availability_zone      = var.compute_az
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false

  backup_retention_period = var.db_backup_retention_days
  apply_immediately       = var.db_apply_immediately
  skip_final_snapshot     = var.db_skip_final_snapshot
  deletion_protection     = var.db_deletion_protection

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres"
  })
}
