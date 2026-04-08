variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the bastion host will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the bastion host (Amazon Linux)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the bastion"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "AWS EC2 Key Pair name for SSH access"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation (e.g. 203.0.113.1/32) — only this IP can SSH to the bastion"
  type        = string
}
