# //////////////////////////////
# VARIABLES
# //////////////////////////////
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "ssh_key_name" {}

variable "private_key_path" {}

variable "webhook_slack" {}

variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "subnet1_cidr" {
  default = "172.16.0.0/24"
}

# //////////////////////////////
# PROVIDERS
# //////////////////////////////
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# //////////////////////////////
# RESOURCES
# //////////////////////////////

# VPC
resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = "true"

  tags = {
    Name = "ada-observability"
  }
}

# SUBNET
resource "aws_subnet" "subnet1" {
  cidr_block              = var.subnet1_cidr
  vpc_id                  = aws_vpc.vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "ada-observability"
  }
}

# IPs Privados
resource "aws_network_interface" "prometheus-privnet" {
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["172.16.0.10"]
  security_groups = [aws_security_group.sg-prometheus-instance.id]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "alertmanager-privnet" {
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["172.16.0.11"]
  security_groups = [aws_security_group.sg-alertmanager-instance.id]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "exporter-privnet" {
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["172.16.0.12"]
  security_groups = [aws_security_group.sg-exporter-instance.id]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "grafana-privnet" {
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["172.16.0.13"]
  security_groups = [aws_security_group.sg-grafana-instance.id]

  tags = {
    Name = "primary_network_interface"
  }
}

# INTERNET_GATEWAY
resource "aws_internet_gateway" "gateway1" {
  vpc_id = aws_vpc.vpc1.id
}

# ROUTE_TABLE
resource "aws_route_table" "route_table1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway1.id
  }
}

resource "aws_route_table_association" "route-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table1.id
}

# SECURITY_GROUP
resource "aws_security_group" "sg-observability-instance" {
  name   = "observability_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-prometheus-instance" {
  name   = "prometheus_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-grafana-instance" {
  name   = "grafana_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-exporter-instance" {
  name   = "exporter_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-alertmanager-instance" {
  name   = "alertmanager_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# INSTANCE
resource "aws_instance" "prometheus-projeto" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
#  subnet_id              = aws_subnet.subnet1.id
#  vpc_security_group_ids = [aws_security_group.sg-prometheus-instance.id]
  key_name               = var.ssh_key_name
  user_data              = file("${path.module}/startup-prometheus.sh")

  tags = {
    Name = "prometheus-projeto"
    "Terraform" = "Yes"
  }

  network_interface {
    network_interface_id = aws_network_interface.prometheus-privnet.id
    device_index         = 0
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }
}

resource "aws_instance" "grafana-projeto" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
#  subnet_id              = aws_subnet.subnet1.id
#  vpc_security_group_ids = [aws_security_group.sg-grafana-instance.id]
  key_name               = var.ssh_key_name
  user_data              = file("${path.module}/startup-grafana.sh")

  tags = {
    Name = "grafana-projeto"
    "Terraform" = "Yes"
  }

  network_interface {
    network_interface_id = aws_network_interface.grafana-privnet.id
    device_index         = 0
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }
}

resource "aws_instance" "exporter-projeto" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
#  subnet_id              = aws_subnet.subnet1.id
#  vpc_security_group_ids = [aws_security_group.sg-exporter-instance.id]
  key_name               = var.ssh_key_name
  user_data              = file("${path.module}/startup-exporter.sh")

  tags = {
    Name = "exporter-projeto"
    "Terraform" = "Yes"
  }

  network_interface {
    network_interface_id = aws_network_interface.exporter-privnet.id
    device_index         = 0
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }
}

resource "aws_instance" "alertmanager-projeto" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
#  subnet_id              = aws_subnet.subnet1.id
#  vpc_security_group_ids = [aws_security_group.sg-alertmanager-instance.id]
  key_name               = var.ssh_key_name
  #user_data              = file("${path.module}/startup-alertmanager.sh")
  user_data = <<EOF
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

echo -e "
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
" >  /etc/alertmanager/alertmanager.yml

echo -e "
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
"> /etc/systemd/system/alertmanager.service

sleep 2

sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool /usr/local/bin/alertmanager

sudo systemctl daemon-reload
sleep 2
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
EOF

  tags = {
    Name = "alertmanager-projeto"
    "Terraform" = "Yes"
  }

  network_interface {
    network_interface_id = aws_network_interface.alertmanager-privnet.id
    device_index         = 0
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }
}
/*
resource "aws_instance" "graylog-projeto" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.small"
#  subnet_id              = aws_subnet.subnet1.id
#  vpc_security_group_ids = [aws_security_group.sg-alertmanager-instance.id]
  key_name               = var.ssh_key_name
  user_data              = file("${path.module}/startup-alertmanager.sh")

  tags = {
    Name = "graylog-projeto"
    "Terraform" = "Yes"
  }

  network_interface {
    network_interface_id = aws_network_interface.graylog-privnet.id
    device_index         = 0
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }
}

*/
# //////////////////////////////
# DATA
# //////////////////////////////
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "aws-linux" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# //////////////////////////////
# OUTPUT
# //////////////////////////////
output "prometheus-dns" {
  value = aws_instance.prometheus-projeto.public_dns
}

output "grafana-dns" {
  value = aws_instance.grafana-projeto.public_dns
}

output "exporter-dns" {
  value = aws_instance.exporter-projeto.public_dns
}

output "alertmanager-dns" {
  value = aws_instance.alertmanager-projeto.public_dns
}
