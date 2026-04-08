output "controller_public_ip" {
  description = "Public IP address of the Ansible controller"
  value       = aws_instance.ansible_controller.public_ip
}

output "controller_instance_id" {
  description = "Instance ID of the Ansible controller"
  value       = aws_instance.ansible_controller.id
}

output "controller_private_ip" {
  description = "Private IP address of the Ansible controller"
  value       = aws_instance.ansible_controller.private_ip
}

output "controller_security_group_id" {
  description = "Security group ID of the Ansible controller"
  value       = aws_security_group.ansible_controller.id
}
