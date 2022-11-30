#!/bin/sh

sudo useradd --no-create-home prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

wget https://github.com/prometheus/prometheus/releases/download/v2.40.2/prometheus-2.40.2.linux-amd64.tar.gz
tar xf prometheus-2.40.2.linux-amd64.tar.gz

sudo cp prometheus-2.40.2.linux-amd64/prometheus /usr/local/bin
sudo cp prometheus-2.40.2.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-2.40.2.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.40.2.linux-amd64/console_libraries /etc/prometheus

sudo cp prometheus-2.40.2.linux-amd64/promtool /var/lib/prometheus
rm -rf prometheus-2.40.2.linux-amd64.tar.gz prometheus-2.40.2.linux-amd64

sudo cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'prometheus'

rule_files:
  - rules.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'exporter'
    static_configs:
      - targets: ['172.16.0.12:9100']

alerting:
  alertmanagers:
    - static_configs:
      - targets: ['172.16.0.11:9093']
EOF

sudo cat > /etc/prometheus/rules.yml << EOF
groups:
- name: AllInstances
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    annotations:
      title: 'Instance {{ $labels.instance }} down'
      description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute.'
    labels:
      severity: 'critical'
EOF

sudo cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

sleep 2

sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

sudo systemctl daemon-reload
sleep 2
sudo systemctl enable prometheus
sudo systemctl start prometheus
