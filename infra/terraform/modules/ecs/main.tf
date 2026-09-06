resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.env}-cluster"

  tags = {
    Project = var.project
    Env     = var.env
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-${var.env}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name         = "gunicorn"
      image        = "${var.ecr_repository_url}:latest"
      command      = ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "config.wsgi:application"]
      essential    = true
      portMappings = [{ containerPort = 8000, protocol = "tcp" }]
      environment = [
        { name = "DJANGO_SETTINGS_MODULE", value = "config.settings.production" },
        { name = "DEBUG", value = "False" },
        { name = "ALLOWED_HOSTS", value = "*" }
      ]
      secrets = [
        { name = "POSTGRES_DB", valueFrom = "${var.db_secret_arn}:dbname::" },
        { name = "POSTGRES_USER", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "POSTGRES_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
        { name = "POSTGRES_HOST", valueFrom = "${var.db_secret_arn}:host::" },
        { name = "POSTGRES_PORT", valueFrom = "${var.db_secret_arn}:port::" },
        { name = "SECRET_KEY", valueFrom = var.django_secret_arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "gunicorn"
        }
      }
    },
    {
      name    = "daphne"
      image   = "${var.ecr_repository_url}:latest"
      command = ["daphne", "-b", "0.0.0.0", "-p", "8001", "config.asgi:application"]
      # essential=false 이유: docs/interview/ecs-concepts.md 9번
      essential    = false
      portMappings = [{ containerPort = 8001, protocol = "tcp" }]
      environment = [
        { name = "DJANGO_SETTINGS_MODULE", value = "config.settings.production" },
        { name = "DEBUG", value = "False" },
        { name = "ALLOWED_HOSTS", value = "*" }
      ]
      secrets = [
        { name = "POSTGRES_DB", valueFrom = "${var.db_secret_arn}:dbname::" },
        { name = "POSTGRES_USER", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "POSTGRES_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
        { name = "POSTGRES_HOST", valueFrom = "${var.db_secret_arn}:host::" },
        { name = "POSTGRES_PORT", valueFrom = "${var.db_secret_arn}:port::" },
        { name = "SECRET_KEY", valueFrom = var.django_secret_arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "daphne"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project}-${var.env}"
  retention_in_days = 7
}

resource "aws_ecs_service" "app" {
  name            = "${var.project}-${var.env}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet_id, var.subnet_id_b]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }
}
