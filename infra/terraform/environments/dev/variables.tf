variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  type    = string
  default = "disasterkok"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "my_ip" {
  type        = string
  description = "Your IP for SSH access"
}

variable "key_name" {
  type        = string
  description = "EC2 Key Pair 이름"
}

variable "k3s_version" {
  type    = string
  default = "v1.32.3+k3s1"
}

variable "github_repo" {
  type        = string
  description = "GitHub 레포지토리 (owner/repo 형식)"
}

variable "public_subnet_cidr_b" {
  type        = string
  description = "두 번째 퍼블릭 서브넷 CIDR (RDS subnet group이 최소 2개 AZ를 요구해서 추가)"
  default     = "10.0.2.0/24"
}

variable "az_b" {
  type        = string
  description = "두 번째 퍼블릭 서브넷 가용 영역 (기존 서브넷과 다른 AZ)"
  default     = "ap-northeast-2c"
}