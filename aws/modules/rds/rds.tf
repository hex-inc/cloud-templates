locals {
  dbname                     = "hextech"
  dbusername                 = "hextech"
  db_ingress_security_groups = var.db_tunnel_subnet != null ? concat(var.security_groups, [aws_security_group.db-tunnel[0].id]) : var.security_groups
}

resource "aws_kms_key" "rds" {
  description         = "Encryption key for RDS"
  enable_key_rotation = true

  tags = {
    "hex-deployment" = var.name
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.name}/rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "Allow worker nodes to connect to the DB"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = local.db_ingress_security_groups
  }

  tags = {
    "hex-deployment" = var.name
  }
}

resource "aws_db_instance" "default" {
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "11"
  instance_class        = var.instance_type
  # hex is a reserved name unfortunately
  name     = local.dbname
  username = local.dbusername
  password = random_password.postgres-password.result

  storage_encrypted = true
  kms_key_id        = aws_kms_alias.rds.target_key_arn

  backup_retention_period = 30
  db_subnet_group_name    = var.database_subnet_group
  vpc_security_group_ids  = [aws_security_group.db.id]

  final_snapshot_identifier = "final-snapshot-${var.name}"
  identifier                = var.name

  tags = {
    "hex-deployment" = var.name
  }
}

resource "aws_security_group" "db-tunnel" {
  count       = var.db_tunnel_subnet != null ? 1 : 0
  name        = "${var.name}-db-tunnel"
  description = "SSH tunnel for DB access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "db-tunnel-ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db-tunnel[0].id
}

resource "aws_security_group_rule" "db-tunnel-egress" {
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_groups   = [aws_security_group.db.id]
  security_group_id = aws_security_group.db-tunnel[0].id
}

resource "aws_instance" "db-tunnel" {
  count                  = var.db_tunnel_subnet != null ? 1 : 0
  ami                    = "ami-0a0ad6b70e61be944" // Amazon Linux 2 AMI (HVM), SSD Volume Type 
  instance_type          = "t2.micro"
  subnet_id              = var.db_tunnel_subnet
  vpc_security_group_ids = [aws_security_group.db-tunnel[0].id]
  tags = {
    "Name" = "${var.name}-db-tunnel"
  }
}

resource "random_password" "postgres-password" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "postgres-password" {
  name  = "/${var.name}/rds/password"
  type  = "SecureString"
  value = random_password.postgres-password.result

  tags = {
    "hex-deployment" = var.name
  }
}
