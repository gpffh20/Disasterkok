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
      # essential=false로 지정: 일회성 migrate RunTask 시 gunicorn(essential=true) 컨테이너가
      # migrate 실행 후 종료되면 task 전체가 정상 종료되어야 하는데, daphne이 essential=true면
      # 계속 떠 있어서 task가 안 끝나고 "aws ecs wait tasks-stopped"가 멈춘다.
      # 트레이드오프: 서비스 운영 중 daphne만 단독으로 죽으면 task 전체 재시작 없이는
      # 복구가 안 됨 — Phase 1 범위에서는 감수, 필요해지면 별도 서비스로 분리 고려.
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
