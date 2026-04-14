data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "main" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile = var.instance_profile_name
  key_name             = var.key_name

  tags = {
    Name    = "${var.project}-${var.env}-node"
    Project = var.project
    Env     = var.env
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    k3s_version = var.k3s_version
  })

user_data_replace_on_change = true
}
