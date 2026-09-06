variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "github_repo" {
  type        = string
  description = "GitHub 레포지토리 (owner/repo 형식)"
}

variable "db_secret_arn" {
  type        = string
  description = "ECS task role에 Secrets Manager 읽기 권한을 줄 대상 secret ARN"
  default     = ""
}