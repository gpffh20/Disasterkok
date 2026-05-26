variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "k3s_version" {
  type        = string
  description = "설치할 k3s 버전 (예: v1.32.3+k3s1)"
}

variable "ecr_registry" {
  type        = string
  description = "ECR 레지스트리 URL (예: 123456789012.dkr.ecr.us-west-2.amazonaws.com)"
}

variable "aws_region" {
  type        = string
  description = "AWS 리전 (예: us-west-2)"
}
