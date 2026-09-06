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

variable "db_secret_arn" {
  description = "RDS 자격증명이 담긴 Secrets Manager secret ARN (JSON: username/password/host/port/dbname)"
  type        = string
}

variable "django_secret_arn" {
  description = "Django SECRET_KEY가 담긴 Secrets Manager secret ARN"
  type        = string
}

variable "grafana_secret_arn" {
  description = "Grafana Cloud API 토큰이 담긴 Secrets Manager secret ARN"
  type        = string
}

variable "grafana_cloud_prometheus_url" {
  description = "Grafana Cloud Hosted Prometheus remote_write endpoint URL"
  type        = string
}

variable "grafana_cloud_username" {
  description = "Grafana Cloud Hosted Prometheus instance ID (basic auth username)"
  type        = string
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
