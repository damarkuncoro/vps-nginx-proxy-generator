# 🚀 VPS nginx-proxy Generator

Auto setup VPS:
- nginx-proxy
- acme-companion
- Multi-domain
- Wildcard SSL (Cloudflare DNS)

## 🔧 Requirements
- Ubuntu 20.04 / 22.04
- Domain using Cloudflare DNS
- Cloudflare API Token

## ⚡ Quick Start

```bash
    git clone https://github.com/damarkuncoro/vps-nginx-proxy-generator.git
    cd vps-nginx-proxy-generator
    chmod +x scripts/*.sh
    sudo ./scripts/vps-proxy-generator.sh


## 🔑 Create Cloudflare secret

```bash
    cp templates/cloudflare.env.example /opt/nginx-proxy/secrets/cloudflare.env
    nano /opt/nginx-proxy/secrets/cloudflare.env
# Add your Cloudflare API Token


## 🌍 Deploy App
```bash
sudo ./scripts/app-generator.sh

## 🌍 Deploy Wildcard App
```bash 
    sudo ./scripts/wildcard-app-generator.sh
