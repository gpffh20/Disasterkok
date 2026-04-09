variable "aws_region" {
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  type        = string
  default     = "disasterkok"
}

variable "env" {
  type        = string
  default     = "dev"
}

variable "my_ip" {
  type        = string
  description = "Your IP for SSH access"
}