#!/bin/bash
set -e

PROXY_DIR="/opt/nginx-proxy"
NETWORK="proxy"

echo "🚀 VPS nginx-proxy + acme-companion generator"

read -p "📧 Default Let's Encrypt Email: " LE_EMAIL

apt update && apt upgrade -y
apt install -y ca-certificates curl gnupg lsb-release ufw docker-compose

if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | bash
fi

systemctl enable docker
systemctl start docker

ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

docker network inspect $NETWORK >/dev/null 2>&1 || docker network create $NETWORK

mkdir -p $PROXY_DIR/{data/nginx/{certs,vhost.d,html},secrets}
cd $PROXY_DIR

cat <<EOF > docker-compose.yml
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy
    container_name: nginx-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./data/nginx/certs:/etc/nginx/certs
      - ./data/nginx/vhost.d:/etc/nginx/vhost.d
      - ./data/nginx/html:/usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - proxy

  acme-companion:
    image: nginxproxy/acme-companion
    container_name: nginx-proxy-acme
    restart: always
    depends_on:
      - nginx-proxy
    environment:
      - DEFAULT_EMAIL=${LE_EMAIL}
      - NGINX_PROXY_CONTAINER=nginx-proxy
      - DOCKER_HOST=unix:///var/run/docker.sock
      - DNS_PROVIDER=cloudflare
    env_file:
      - ./secrets/cloudflare.env
    volumes:
      - ./data/nginx/certs:/etc/nginx/certs
      - ./data/nginx/vhost.d:/etc/nginx/vhost.d
      - ./data/nginx/html:/usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF

echo "✅ nginx-proxy stack generated"
echo "➡️ Jangan lupa buat secrets/cloudflare.env"
