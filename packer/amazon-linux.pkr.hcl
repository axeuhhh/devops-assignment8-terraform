packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# ─── Variables ────────────────────────────────────────────────────────────────

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# Your SSH public key — injected into the AMI's authorized_keys at build time.
# Override with:  packer build -var 'ssh_public_key=<key>' amazon-linux.pkr.hcl
variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs0swI3od4BvgjwqhybCLCLSuu1Fr3Ve47WckwZuCOzr7sItKKR9IspDroNO2QgtoWnCRPDpUw1k9DLDOLZ1Nz5Tio4QHKRlcRFiZcLev+MSNoD2LtWWfSr8iAUH3zYcXTL2vb3QNZweuhV78bAP/DcFM5T46Vcqr8gl7WRKn/PGxourqggdgBFKsZzcnUbuVa9qs08NKx22wGX5oRbF2wruFxQRikbHO/xLdypSdu5LrwCTEmAwM3ckorzcb9PkxGBTguJQJ72Iu9vn9Plj1iERxOqr2+tgWCSV/G88FPJlO2W1HiIzLLJd9Kvz3ACL/8glpRmy5Y+nRsBPagWTcX"
}

# ─── Data Sources ─────────────────────────────────────────────────────────────

# Dynamically resolve the latest Amazon Linux 2023 AMI so the build is
# always current without hard-coding an AMI ID.
data "amazon-ami" "amazon-linux-2023" {
  filters = {
    name                = "al2023-ami-*-x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = var.aws_region
}

# ─── Source ───────────────────────────────────────────────────────────────────

source "amazon-ebs" "amazon-linux-docker" {
  region        = var.aws_region
  instance_type = var.instance_type
  source_ami    = data.amazon-ami.amazon-linux-2023.id

  # Packer uses its own temporary key-pair to connect during the build.
  ssh_username = "ec2-user"

  ami_name        = "amazon-linux-docker-prometheus-{{timestamp}}"
  ami_description = "Amazon Linux 2023 with Docker, Node Exporter, and custom SSH key"

  tags = {
    Name        = "amazon-linux-docker-prometheus"
    Environment = "devops-assignment8"
    Builder     = "Packer"
  }
}

# ─── Build ────────────────────────────────────────────────────────────────────

build {
  name    = "amazon-linux-docker"
  sources = ["source.amazon-ebs.amazon-linux-docker"]

  # 1. Install Docker
  provisioner "shell" {
    script = "scripts/install_docker.sh"
  }

  # 2. Install Prometheus Node Exporter (exposes host metrics on :9100)
  provisioner "shell" {
    script = "scripts/install_node_exporter.sh"
  }

  # 3. Inject the SSH public key into authorized_keys
  provisioner "shell" {
    inline = [
      "mkdir -p /home/ec2-user/.ssh",
      "chmod 700 /home/ec2-user/.ssh",
      "echo '${var.ssh_public_key}' >> /home/ec2-user/.ssh/authorized_keys",
      "chmod 600 /home/ec2-user/.ssh/authorized_keys",
      "chown -R ec2-user:ec2-user /home/ec2-user/.ssh",
      "echo 'SSH public key injected successfully'"
    ]
  }

  # 4. Verify the build
  provisioner "shell" {
    inline = [
      "echo 'Build verification:'",
      "docker --version",
      "node_exporter --version",
      "systemctl is-enabled node_exporter",
      "cat /home/ec2-user/.ssh/authorized_keys | wc -l",
      "echo 'Build complete!'"
    ]
  }
}
