locals {
  dbname     = "hextech"
  dbusername = "hextech"
}

resource "aws_security_group" "db" {
  name        = "${local.name}-db"
  description = "Allow worker nodes to connect to the DB"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "hex-deployment" = local.name
  }
}

resource "aws_kms_key" "rds" {
  description         = "Encryption key for RDS"
  enable_key_rotation = true

  tags = {
    "hex-deployment" = local.name
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name}/rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_subnet_group" "db" {
  name = "${local.name}-db"
  subnet_ids = [
    module.public-subnet-a.subnet_id,
    module.public-subnet-b.subnet_id,
    module.public-subnet-c.subnet_id
  ]

  tags = {
    Name             = "${local.name}-db"
    "hex-deployment" = local.name
  }
}

resource "aws_db_instance" "default" {
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "11.6"
  instance_class        = "db.m5.large"
  # hex is a reserved name unfortunately
  name     = local.dbname
  username = local.dbusername
  password = random_password.postgres-password.result

  storage_encrypted = true
  kms_key_id        = aws_kms_alias.rds.target_key_arn

  backup_retention_period = 30
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.db.id]

  final_snapshot_identifier = "final-snapshot-${local.name}"
  identifier                = local.name

  tags = {
    "hex-deployment" = local.name
  }
}

resource "random_password" "postgres-password" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "postgres-password" {
  name  = "/${local.name}/postgres-password"
  type  = "SecureString"
  value = random_password.postgres-password.result

  tags = {
    "hex-deployment" = local.name
  }
}
