# ─── monitoring.tf ────────────────────────────────────────────────────────────
# Deploys one EC2 instance for Prometheus and one for Grafana in the private
# subnet.  Both use the same custom AMI (Docker + Node Exporter pre-installed).
#
# Data flow:
#   App servers (×6) ──► node_exporter :9100 ──► Prometheus :9090 ──► Grafana :3000
#   Prometheus host  ──► node_exporter :9100 ──► Prometheus (localhost)
# ─────────────────────────────────────────────────────────────────────────────

# ─── Locals ───────────────────────────────────────────────────────────────────

locals {
  # Prometheus YAML — built from known app-server IPs.
  # Prometheus also scrapes itself via localhost:9100.
  prometheus_yml = <<-YAML
    global:
      scrape_interval:     15s
      evaluation_interval: 15s

    scrape_configs:
      - job_name: 'node'
        static_configs:
          - targets:
              - 'localhost:9100'
%{ for ip in module.private_instances.private_instance_ips ~}
              - '${ip}:9100'
%{ endfor ~}
  YAML

  # Grafana datasource — points at the Prometheus instance created below.
  grafana_datasource_yml = <<-YAML
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        uid: prometheus
        access: proxy
        url: http://${aws_instance.prometheus.private_ip}:9090
        isDefault: true
        editable: false
  YAML

  # Grafana dashboard provider — tells Grafana where to load dashboards from.
  grafana_dashboard_provider_yml = <<-YAML
    apiVersion: 1
    providers:
      - name: default
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        updateIntervalSeconds: 30
        options:
          path: /var/lib/grafana/dashboards
  YAML
}

# ─── Security Group (shared by Prometheus and Grafana) ────────────────────────

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-monitoring-sg"
  description = "SSH from bastion; Prometheus :9090, Grafana :3000, Node Exporter :9100 from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.bastion.bastion_security_group_id]
  }

  ingress {
    description = "Prometheus UI from VPC"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Grafana UI from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Node Exporter metrics from VPC"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound (Docker pulls via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-monitoring-sg"
    Project = var.project_name
  }
}

# ─── Prometheus EC2 Instance ──────────────────────────────────────────────────

resource "aws_instance" "prometheus" {
  ami           = var.custom_ami_id
  instance_type = var.monitoring_instance_type

  # Place in the first private subnet
  subnet_id = module.vpc.private_subnet_ids[0]

  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  user_data = <<-SCRIPT
    #!/bin/bash
    set -e

    # Wait for Docker daemon to be ready
    while ! docker info > /dev/null 2>&1; do sleep 2; done

    mkdir -p /opt/prometheus

    # Write prometheus.yml (base64-encoded to avoid shell quoting issues)
    echo '${base64encode(local.prometheus_yml)}' | base64 -d > /opt/prometheus/prometheus.yml

    # Start Prometheus container
    docker run -d \
      --name prometheus \
      --restart always \
      -p 9090:9090 \
      -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
      prom/prometheus:latest \
        --config.file=/etc/prometheus/prometheus.yml \
        --storage.tsdb.path=/prometheus \
        --web.console.libraries=/etc/prometheus/console_libraries \
        --web.console.templates=/etc/prometheus/consoles \
        --web.enable-lifecycle

    echo "Prometheus started on :9090"
  SCRIPT

  tags = {
    Name    = "${var.project_name}-prometheus"
    Role    = "monitoring"
    Project = var.project_name
  }
}

# ─── Grafana EC2 Instance ─────────────────────────────────────────────────────
# Depends on Prometheus (references its private IP in the datasource config).

resource "aws_instance" "grafana" {
  ami           = var.custom_ami_id
  instance_type = var.monitoring_instance_type

  # Place in the second private subnet for AZ diversity
  subnet_id = module.vpc.private_subnet_ids[1]

  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  user_data = <<-SCRIPT
    #!/bin/bash
    set -e

    # Wait for Docker daemon to be ready
    while ! docker info > /dev/null 2>&1; do sleep 2; done

    # Create provisioning directory structure
    mkdir -p /opt/grafana/provisioning/datasources
    mkdir -p /opt/grafana/provisioning/dashboards
    mkdir -p /opt/grafana/dashboards

    # Datasource: Prometheus
    echo '${base64encode(local.grafana_datasource_yml)}' \
      | base64 -d > /opt/grafana/provisioning/datasources/prometheus.yml

    # Dashboard provider config
    echo '${base64encode(local.grafana_dashboard_provider_yml)}' \
      | base64 -d > /opt/grafana/provisioning/dashboards/provider.yml

    # Infrastructure dashboard (CPU + Memory)
    echo '${base64encode(file("${path.module}/templates/dashboard.json"))}' \
      | base64 -d > /opt/grafana/dashboards/infrastructure.json

    # Start Grafana container
    docker run -d \
      --name grafana \
      --restart always \
      -p 3000:3000 \
      -e GF_SECURITY_ADMIN_USER=admin \
      -e GF_SECURITY_ADMIN_PASSWORD=admin \
      -e GF_USERS_ALLOW_SIGN_UP=false \
      -e GF_AUTH_ANONYMOUS_ENABLED=false \
      -v /opt/grafana/provisioning:/etc/grafana/provisioning:ro \
      -v /opt/grafana/dashboards:/var/lib/grafana/dashboards:ro \
      grafana/grafana:latest

    echo "Grafana started on :3000"
  SCRIPT

  tags = {
    Name    = "${var.project_name}-grafana"
    Role    = "monitoring"
    Project = var.project_name
  }
}
