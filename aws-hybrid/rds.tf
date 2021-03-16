locals {
  dbname     = "hextech"
  dbusername = "hextech"
}

resource "aws_kms_key" "rds" {
  description         = "Hex Encryption key for RDS"
  enable_key_rotation = true
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.name}/rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "Allow worker nodes to connect to the DB"
  vpc_id      = module.vpc.vpc_id
  # ingress {
  #   from_port       = 5432
  #   to_port         = 5432
  #   protocol        = "tcp"
  #   security_groups = []
  # }
}

resource "aws_db_instance" "hex" {
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "11"
  instance_class        = "db.m5.large"

  # hex is a reserved named, so we use hextech
  name     = local.dbname
  username = local.dbusername
  password = random_password.postgres-password.result

  storage_encrypted = true
  kms_key_id        = aws_kms_alias.rds.target_key_arn

  backup_retention_period = 30
  db_subnet_group_name    = module.vpc.database_subnet_group
  vpc_security_group_ids  = [aws_security_group.db.id]

  final_snapshot_identifier = "final-snapshot-${var.name}"
  identifier                = var.name
}

resource "random_password" "postgres-password" {
  length  = 32
  special = false
}
