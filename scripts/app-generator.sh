#!/bin/bash
set -e

read -p "🌍 Domain (example.com): " DOMAIN
read -p "📧 SSL Email: " EMAIL

APP_DIR="/opt/apps/$DOMAIN"
mkdir -p $APP_DIR
cd $APP_DIR

cat <<EOF > docker-compose.yml
services:
  app:
    image: nginx
    restart: always
    environment:
      - VIRTUAL_HOST=$DOMAIN,www.$DOMAIN
      - LETSENCRYPT_HOST=$DOMAIN,www.$DOMAIN
      - LETSENCRYPT_EMAIL=$EMAIL
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF

docker-compose up -d
echo "🚀 $DOMAIN deployed"
