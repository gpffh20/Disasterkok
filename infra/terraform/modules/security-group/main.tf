resource "aws_security_group" "k3s" {
  name        = "${var.project}-${var.env}-k3s-sg"
  description = "Security group for k3s node"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "k3s API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${var.env}-k3s-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.env}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    # ALB 없이 task 퍼블릭 IP로 직접 라우팅(Phase 1) — 컨테이너가 실제 리슨하는 8000번을 연다.
    # nginx를 앞단에 두게 되면(향후) 80으로 좁히고 8000은 SG 내부 통신으로만 제한할 것.
    description = "Gunicorn direct (no ALB, Phase 1)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${var.env}-ecs-sg"
    Project = var.project
    Env     = var.env
  }
}
