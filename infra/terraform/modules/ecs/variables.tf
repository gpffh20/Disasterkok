variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "execution_role_arn" {
  description = "ECS execution role ARN (ECR pull + CloudWatch Logs 쓰기)"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN (애플리케이션 코드가 사용하는 권한)"
  type        = string
}

variable "ecr_repository_url" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "subnet_id_b" {
  type = string
}

variable "security_group_id" {
  type = string
}
