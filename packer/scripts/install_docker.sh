#!/bin/bash
set -e

echo "==> Updating system packages"
sudo yum update -y

echo "==> Installing Docker"
sudo yum install -y docker

echo "==> Starting and enabling Docker service"
sudo systemctl start docker
sudo systemctl enable docker

echo "==> Adding ec2-user to docker group"
sudo usermod -aG docker ec2-user

echo "==> Verifying Docker installation"
docker --version

echo "==> Docker installation complete"
