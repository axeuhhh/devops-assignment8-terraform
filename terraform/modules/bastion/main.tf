# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH only from the operator IP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from operator IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-bastion-sg"
    Project = var.project_name
  }
}

# ─── Bastion EC2 Instance ─────────────────────────────────────────────────────

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # The bastion needs the private key to hop into private instances.
  # We pass it via user_data so it exists on first boot.
  user_data = <<-EOF
    #!/bin/bash
    # Allow agent forwarding — private key stays on the operator's laptop.
    echo "Host *" >> /home/ec2-user/.ssh/config
    echo "  StrictHostKeyChecking no" >> /home/ec2-user/.ssh/config
    chown ec2-user:ec2-user /home/ec2-user/.ssh/config
    chmod 600 /home/ec2-user/.ssh/config
  EOF

  tags = {
    Name    = "${var.project_name}-bastion"
    Role    = "bastion"
    Project = var.project_name
  }
}
