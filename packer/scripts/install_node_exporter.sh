#!/bin/bash
set -e

NODE_EXPORTER_VERSION="1.8.2"
ARCH="linux-amd64"
DOWNLOAD_DIR="/tmp"

echo "==> Downloading Node Exporter ${NODE_EXPORTER_VERSION}"
curl -L \
  "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz" \
  -o "${DOWNLOAD_DIR}/node_exporter.tar.gz"

echo "==> Extracting Node Exporter"
tar -xzf "${DOWNLOAD_DIR}/node_exporter.tar.gz" -C "${DOWNLOAD_DIR}"
sudo mv "${DOWNLOAD_DIR}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" /usr/local/bin/
rm -rf "${DOWNLOAD_DIR}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}" "${DOWNLOAD_DIR}/node_exporter.tar.gz"

echo "==> Creating node_exporter system user"
sudo useradd --system --no-create-home --shell /sbin/nologin node_exporter || true

echo "==> Creating systemd service for Node Exporter"
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'SERVICE'
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.processes

[Install]
WantedBy=multi-user.target
SERVICE

echo "==> Enabling and starting Node Exporter"
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "==> Node Exporter installation complete"
/usr/local/bin/node_exporter --version
