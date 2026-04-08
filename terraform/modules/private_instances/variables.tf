variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to distribute instances across"
  type        = list(string)
}

variable "ami_id" {
  description = "Custom AMI ID built by Packer (Amazon Linux + Docker)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of private EC2 instances to create"
  type        = number
  default     = 6
}

variable "key_name" {
  description = "AWS EC2 Key Pair name for SSH access"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host — only it may SSH into private instances"
  type        = string
}
