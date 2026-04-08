terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
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

# ─── Private Instances Module ─────────────────────────────────────────────────

module "private_instances" {
  source = "./modules/private_instances"

  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  ami_id                    = var.custom_ami_id
  instance_type             = var.private_instance_type
  instance_count            = var.private_instance_count
  key_name                  = var.key_name
  bastion_security_group_id = module.bastion.bastion_security_group_id
}
