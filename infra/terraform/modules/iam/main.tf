# EC2가 AWS 서비스를 assume 할 수 있도록 허용하는 Trust Policy
resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.env}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# ECR에서 이미지를 pull 할 수 있는 권한 부여
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EC2에 IAM Role을 연결하기 위한 Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.env}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# GitHub Actions OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# GitHub Actions ECR 푸시용 IAM Role
resource "aws_iam_role" "github_actions" {
  name = "${var.project}-${var.env}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}

# ECR 이미지 푸시 권한
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# EC2가 SSM Agent로 SSM 연결 권한
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "github_actions_ecs" {
  name = "${var.project}-${var.env}-github-actions-ecs"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ec2:DescribeNetworkInterfaces"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["iam:PassRole"],
        Resource = [
          aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      }
    ]
  })
}

# ECS task가 assume하는 Trust Policy (execution role, task role 공용)
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS execution role: ECR pull + CloudWatch Logs 쓰기
resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project}-${var.env}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS task role: 컨테이너 안 애플리케이션 코드가 실제로 사용하는 권한 (지금은 최소, Secrets Manager 연동 시 추가 예정)
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project}-${var.env}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

# ECS execution role이 컨테이너 시작 전 Secret을 읽을 수 있는 권한.
# 주의: task definition의 `secrets` 필드로 주입되는 값은 task role이 아니라
# execution role 권한으로 조회된다 (task role은 컨테이너 실행 중 앱 코드가
# AWS API를 직접 호출할 때만 쓰인다). 처음에 이걸 task_role에 잘못 붙였다가
# "AccessDeniedException ... assumed-role/ecs-execution-role"로 확인 후 수정함.
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  count = var.db_secret_arn != "" ? 1 : 0
  name  = "${var.project}-${var.env}-ecs-execution-secrets"
  role  = aws_iam_role.ecs_execution.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = compact([var.db_secret_arn, var.django_secret_arn])
    }]
  })
}

# Github Actions가 SSM을 통해 EC2에 명령 전송 권한
resource "aws_iam_role_policy" "github_actions_ssm" {
  name = "${var.project}-${var.env}-github-actions-ssm"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ssm:SendCommand", "ssm:GetCommandInvocation"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeInstances"],
        Resource = "*"
      }
    ]
  })
}
