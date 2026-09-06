resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.env}-db-subnet-group"
  subnet_ids = [var.subnet_id, var.subnet_id_b]

  tags = {
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.env}-rds-sg"
  description = "Security group for RDS Postgres"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from ECS tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${var.env}-rds-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_db_instance" "main" {
  identifier              = "${var.project}-${var.env}-db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = {
    Project = var.project
    Env     = var.env
  }
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.project}-${var.env}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = var.db_name
  })
}
