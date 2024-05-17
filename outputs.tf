# MongoDB Instance Id
output "db_instance_id" {
  description = "MongoDB EC2 instance Id"
  value       = module.ec2_instance.id
}

# MongoDB Public IP
output "db_instance_public_ip" {
  description = "MongoDB Public IP address"
  value       = module.ec2_instance.public_ip
}

# MongoDB DNS Info
output "ec2_instance_dns_name" {
  description = "MongoDB DNS Name"
  value       = module.ec2_instance.public_dns
}

# MongoDB private Key-Pair
output "db_instance_private_key" {
  description = "MongoDB private Key Pair info"
  value       = module.key_pair.private_key_openssh
  sensitive   = true
}
