
# Laboratorio de Observabilidade

## Graylog
Deploy de VM com Virtualbox via vagrant.
Este script contempla:

- Instalação do docker
- Redirecionamento da porta 9000 para a VM
- Deploy de 3 containers (MongoDB, Elastic Search e Graylog)

## Projeto Final
Deploy de instâncias EC2 via terraform na AWS.
Este script contempla:

- Deploy 4 Instâncias EC2 (Prometheus, Node Exporter, Alert Manager e Grafana)
- Configuração e instalação do Grafana via repositório
- Download, instalação e configuração e ativação via systemd (Prometheus, Node Exporter, Alert Manager

### TODO
- Automatizar configuração do Alert Manager
- Automatizar dashboards no Grafana

## Observação
Estes labs foram realizados com as seguintes versões de OS e ferramentas:

Linux Mint 21 "Vanessa"
Virtual Box 6.1.38
Vagrant 2.3.3
Terraform v1.3.5

