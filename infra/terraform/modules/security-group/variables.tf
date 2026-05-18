variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "my_ip" {
  description = "Your IP for SSH access (e.g. 1.2.3.4/32)"
  type        = string
}
