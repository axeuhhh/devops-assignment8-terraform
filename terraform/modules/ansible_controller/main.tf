# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "ansible_controller" {
  name        = "${var.project_name}-ansible-controller-sg"
  description = "Allow SSH from operator IP; allow all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from operator IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound (package installs, SSH to private instances)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-ansible-controller-sg"
    Project = var.project_name
    Role    = "ansible-controller"
  }
}

# ─── Ansible Controller EC2 Instance ─────────────────────────────────────────

resource "aws_instance" "ansible_controller" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.ansible_controller.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Install Ansible on Amazon Linux 2023
    dnf update -y
    dnf install -y python3 python3-pip
    pip3 install ansible

    # Create ansible workspace directory
    mkdir -p /home/ec2-user/ansible/inventory
    chown -R ec2-user:ec2-user /home/ec2-user/ansible

    # Configure SSH to skip host key checking for internal hosts
    cat > /home/ec2-user/.ssh/config <<'SSHCFG'
Host 10.0.*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
SSHCFG
    chown ec2-user:ec2-user /home/ec2-user/.ssh/config
    chmod 600 /home/ec2-user/.ssh/config
  EOF

  tags = {
    Name    = "${var.project_name}-ansible-controller"
    Role    = "ansible-controller"
    Project = var.project_name
  }
}
