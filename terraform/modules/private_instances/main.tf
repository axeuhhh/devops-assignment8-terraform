# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "Allow SSH from bastion only; allow all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  ingress {
    description = "Internal VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outbound (needed for Docker pulls via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-private-sg"
    Project = var.project_name
  }
}

# ─── 6 Private EC2 Instances ──────────────────────────────────────────────────

resource "aws_instance" "private" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type

  # Round-robin across the supplied private subnets
  subnet_id = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]

  vpc_security_group_ids      = [aws_security_group.private.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  tags = {
    Name    = "${var.project_name}-private-${count.index + 1}"
    Role    = "app-server"
    Project = var.project_name
  }
}
