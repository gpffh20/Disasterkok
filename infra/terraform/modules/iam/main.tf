terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}
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
  role = aws_iam_role.ec2.name
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
  role        = aws_iam_role.ec2.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Github Actions가 SSM을 통해 EC2에 명령 전송 권한
resource "aws_iam_role_policy" "github_actions_ssm" {
  name  = "${var.project}-${var.env}-github-actions-ssm"
  role  = aws_iam_role.github_actions.name

policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["ssm:SendCommand", "ssm:GetCommandInvocation"],
      Resource = "*"
    },
      {
        Effect = "Allow",
        Action = ["ec2:DescribeInstances"],
        Resource = "*"
       }
      ]
  })
}