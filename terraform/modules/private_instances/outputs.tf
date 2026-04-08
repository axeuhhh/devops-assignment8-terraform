output "private_instance_ids" {
  description = "List of private EC2 instance IDs"
  value       = aws_instance.private[*].id
}

output "private_instance_ips" {
  description = "List of private IP addresses of the private instances"
  value       = aws_instance.private[*].private_ip
}

output "private_security_group_id" {
  description = "Security group ID used by the private instances"
  value       = aws_security_group.private.id
}
