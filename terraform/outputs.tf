output "instance_public_ip" {
  value       = aws_instance.builder.public_ip
  description = "The public IP of the EC2 instance for verification"
}

output "ssh_key_location" {
  value       = local_file.private_key.filename
  description = "The SSH key location for accessing the instance"
}

output "security_group_id" {
  value       = aws_security_group.builder_sg.id
  description = "The security group ID for reference"
}