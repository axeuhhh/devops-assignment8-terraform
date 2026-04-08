terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── Latest Ubuntu 22.04 LTS AMI (Canonical) ──────────────────────────────────

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ─── VPC Module ───────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ─── Bastion Module ───────────────────────────────────────────────────────────

module "bastion" {
  source = "./modules/bastion"

  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  ami_id           = var.custom_ami_id
  instance_type    = var.bastion_instance_type
  key_name         = var.key_name
  my_ip_cidr       = var.my_ip_cidr
}

# ─── Ansible Controller Module ────────────────────────────────────────────────

module "ansible_controller" {
  source = "./modules/ansible_controller"

  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[1]
  ami_id           = var.custom_ami_id
  instance_type    = var.ansible_controller_instance_type
  key_name         = var.key_name
  my_ip_cidr       = var.my_ip_cidr
}

# ─── Ubuntu Private Instances (3) ─────────────────────────────────────────────

module "ubuntu_instances" {
  source = "./modules/private_instances"

  project_name              = var.project_name
  os_name                   = "ubuntu"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  ami_id                    = data.aws_ami.ubuntu.id
  instance_type             = var.private_instance_type
  instance_count            = 3
  key_name                  = var.key_name
  bastion_security_group_id = module.bastion.bastion_security_group_id
}

# ─── Amazon Linux Private Instances (3) ───────────────────────────────────────

module "amazon_instances" {
  source = "./modules/private_instances"

  project_name              = var.project_name
  os_name                   = "amazon"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  ami_id                    = var.custom_ami_id
  instance_type             = var.private_instance_type
  instance_count            = 3
  key_name                  = var.key_name
  bastion_security_group_id = module.bastion.bastion_security_group_id
}

# ─── Ansible Inventory File (generated locally after apply) ───────────────────

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"
  content = templatefile("${path.module}/templates/hosts.ini.tpl", {
    ubuntu_ips = module.ubuntu_instances.private_instance_ips
    amazon_ips = module.amazon_instances.private_instance_ips
    key_name   = var.key_name
  })
}
