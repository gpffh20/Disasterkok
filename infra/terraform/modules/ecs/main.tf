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
      portMappings = [{ containerPort = 8000, protocol = "tcp" }]
      environment = [
        { name = "DJANGO_SETTINGS_MODULE", value = "config.settings.production" }
      ]
      # DB 자격증명은 Secrets Manager 연동 후 secrets 필드로 추가 예정
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "gunicorn"
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
