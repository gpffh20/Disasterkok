output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "ec2_instance_id" {
    value = module.ec2.instance_id
}
