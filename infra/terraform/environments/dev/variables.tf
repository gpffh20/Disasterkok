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