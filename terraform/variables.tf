variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all AWS resources"
  type        = string
  default     = "cs686-a7"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "key_name" {
  description = "Name of the AWS EC2 Key Pair for SSH access"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in /32 CIDR notation — restricts SSH access to the bastion (e.g. 203.0.113.1/32)"
  type        = string
}

variable "custom_ami_id" {
  description = "AMI ID produced by the Packer build (Amazon Linux + Docker + SSH key)"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t2.micro"
}

variable "private_instance_type" {
  description = "EC2 instance type for private app servers"
  type        = string
  default     = "t2.micro"
}

variable "private_instance_count" {
  description = "Number of private EC2 instances"
  type        = number
  default     = 6
}

variable "monitoring_instance_type" {
  description = "EC2 instance type for the Prometheus and Grafana monitoring hosts"
  type        = string
  default     = "t2.micro"
}
