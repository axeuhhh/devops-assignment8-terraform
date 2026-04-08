output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Bastion host public IP — SSH into this first"
  value       = module.bastion.bastion_public_ip
}

output "private_instance_ips" {
  description = "Private IP addresses of the 6 app servers"
  value       = module.private_instances.private_instance_ips
}

output "ssh_to_bastion" {
  description = "Command to SSH into the bastion host"
  value       = "ssh -A -i <your-private-key.pem> ec2-user@${module.bastion.bastion_public_ip}"
}

output "ssh_tunnel_example" {
  description = "Command to jump through bastion into a private instance (replace <PRIVATE_IP>)"
  value       = "ssh -J ec2-user@${module.bastion.bastion_public_ip} ec2-user@<PRIVATE_IP>"
}

# ─── Monitoring outputs ────────────────────────────────────────────────────────

output "prometheus_private_ip" {
  description = "Private IP of the Prometheus instance"
  value       = aws_instance.prometheus.private_ip
}

output "grafana_private_ip" {
  description = "Private IP of the Grafana instance"
  value       = aws_instance.grafana.private_ip
}

output "prometheus_ssh_tunnel" {
  description = "SSH tunnel command to forward Prometheus UI to localhost:9090"
  value       = "ssh -i <your-key.pem> -L 9090:${aws_instance.prometheus.private_ip}:9090 -J ec2-user@${module.bastion.bastion_public_ip} ec2-user@${aws_instance.prometheus.private_ip}"
}

output "grafana_ssh_tunnel" {
  description = "SSH tunnel command to forward Grafana UI to localhost:3000"
  value       = "ssh -i <your-key.pem> -L 3000:${aws_instance.grafana.private_ip}:3000 -J ec2-user@${module.bastion.bastion_public_ip} ec2-user@${aws_instance.grafana.private_ip}"
}
