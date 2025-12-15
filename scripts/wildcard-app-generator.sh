#!/bin/bash
set -e

read -p "🌍 Root domain (example.com): " DOMAIN
read -p "📧 SSL Email: " EMAIL

APP_DIR="/opt/apps/wildcard-$DOMAIN"
mkdir -p $APP_DIR
cd $APP_DIR

cat <<EOF > docker-compose.yml
services:
  wildcard:
    image: nginx
    restart: always
    environment:
      - VIRTUAL_HOST=*.$DOMAIN
      - LETSENCRYPT_HOST=*.$DOMAIN
      - LETSENCRYPT_EMAIL=$EMAIL
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF

docker-compose up -d
echo "🌟 Wildcard *.$DOMAIN active"
