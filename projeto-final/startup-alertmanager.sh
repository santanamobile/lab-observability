#!/bin/sh
sudo useradd --no-create-home alertmanager
sudo mkdir -p /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager

wget https://github.com/prometheus/alertmanager/releases/download/v0.24.0/alertmanager-0.24.0.linux-amd64.tar.gz
tar xvfz alertmanager-0.24.0.linux-amd64.tar.gz

sudo cp alertmanager-0.24.0.linux-amd64/alertmanager /usr/local/bin
sudo cp alertmanager-0.24.0.linux-amd64/amtool /usr/local/bin/
sudo cp alertmanager-0.24.0.linux-amd64/alertmanager.yml /etc/alertmanager

rm -rf alertmanager*

sudo cat > /etc/alertmanager/alertmanager.yml << EOF
global:
  resolve_timeout: 1m
  slack_api_url: '${var.webhook_slack}'

route:
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#projeto-observabilidade'
    send_resolved: true
EOF

sudo cat > /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=Alert Manager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager

Restart=always

[Install]
WantedBy=multi-user.target
EOF

sleep 2

sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool /usr/local/bin/alertmanager

sudo systemctl daemon-reload
sleep 2
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

