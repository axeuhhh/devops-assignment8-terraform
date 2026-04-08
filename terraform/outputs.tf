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
  description = "Bastion host public IP"
  value       = module.bastion.bastion_public_ip
}

output "ansible_controller_public_ip" {
  description = "Ansible controller public IP — SSH into this to run playbooks"
  value       = module.ansible_controller.controller_public_ip
}

output "ubuntu_instance_ips" {
  description = "Private IPs of the 3 Ubuntu EC2 instances (OS: ubuntu)"
  value       = module.ubuntu_instances.private_instance_ips
}

output "amazon_instance_ips" {
  description = "Private IPs of the 3 Amazon Linux EC2 instances (OS: amazon)"
  value       = module.amazon_instances.private_instance_ips
}

output "ssh_to_bastion" {
  description = "Command to SSH into the bastion host"
  value       = "ssh -A -i <your-key.pem> ec2-user@${module.bastion.bastion_public_ip}"
}

output "ssh_to_ansible_controller" {
  description = "Command to SSH into the Ansible controller"
  value       = "ssh -A -i <your-key.pem> ec2-user@${module.ansible_controller.controller_public_ip}"
}

output "run_playbook" {
  description = "Command to run the Ansible playbook from the controller"
  value       = "ansible-playbook -i ~/ansible/inventory/hosts.ini ~/ansible/playbook.yml"
}
