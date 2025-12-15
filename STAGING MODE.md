# 🧪 1️⃣ STAGING MODE (Let’s Encrypt Sandbox)

Let’s Encrypt punya **server staging**:

* ❌ Sertifikat **TIDAK trusted browser**
* ✅ **Unlimited testing**
* ✅ Aman untuk CI / generator

---

## 🔧 Cara Aktifkan Staging

Di `docker-compose.yml` **acme-companion** tambahkan:

```yaml
environment:
  - DEFAULT_EMAIL=${LE_EMAIL}
  - NGINX_PROXY_CONTAINER=nginx-proxy
  - DOCKER_HOST=unix:///var/run/docker.sock
  - DNS_PROVIDER=cloudflare
  - ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
```

📌 **Ini kunci staging mode**

---

## 🔁 Restart stack

```bash
cd /opt/nginx-proxy
docker-compose down
docker-compose up -d
```

---

## ✅ Output log (contoh sukses)

```bash
docker logs nginx-proxy-acme
```

```text
Using ACME CA: https://acme-staging-v02.api.letsencrypt.org/directory
Successfully received certificate.
```

👉 Browser akan bilang **Not Secure** → **NORMAL**

---

# 🔍 2️⃣ DRY-RUN MODE (NO CERT ISSUE)

Dry-run =
➡️ **Proxy + routing aktif**
➡️ **TANPA request SSL sama sekali**

### Cocok untuk:

* Test DNS
* Test routing
* Test multi-app
* Test wildcard logic

---

## 🔧 Cara Dry-Run di APP

### ❌ JANGAN set LETSENCRYPT_*

```yaml
environment:
  - VIRTUAL_HOST=example.com
```

➡️ nginx-proxy tetap jalan
➡️ acme-companion **tidak request cert**

---

## 🔧 Dry-Run Generator (APP)

Contoh `app-generator-dry.sh`:

```bash
#!/bin/bash
set -e

read -p "🌍 Domain: " DOMAIN

APP_DIR="/opt/apps/dry-$DOMAIN"
mkdir -p $APP_DIR
cd $APP_DIR

cat <<EOF > docker-compose.yml
version: "3.8"

services:
  app:
    image: nginx
    restart: always
    environment:
      - VIRTUAL_HOST=$DOMAIN
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF

docker-compose up -d

echo "🧪 DRY-RUN active for $DOMAIN (HTTP only)"
```

Akses:

```
http://example.com
```

---

# 🔁 3️⃣ SWITCH STAGING → PRODUCTION (SAFE WAY)

### STEP A — Matikan staging

Edit:

```yaml
# HAPUS / COMMENT
- ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
```

---

### STEP B — Remove cert lama (WAJIB)

```bash
rm -rf /opt/nginx-proxy/data/nginx/certs/*
```

---

### STEP C — Restart stack

```bash
docker-compose down
docker-compose up -d
```

➡️ Cert **REAL & trusted** akan terbit

---

# 🧠 FLOW REKOMENDASI (PRO)

```
DNS OK?
   ↓
Dry-run (HTTP only)
   ↓
Staging SSL
   ↓
Production SSL
```

➡️ **Zero rate-limit risk**

---

# 🧪 BONUS — ENV SWITCH (AUTOMATION)

### `.env`

```env
ACME_MODE=staging
```

### `docker-compose.yml`

```yaml
environment:
  - ACME_CA_URI=${ACME_MODE:-prod}
```

### Script switch

```bash
#!/bin/bash

if [ "$1" == "staging" ]; then
  export ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
  echo "🧪 STAGING MODE"
else
  unset ACME_CA_URI
  echo "🔒 PRODUCTION MODE"
fi

docker-compose down
docker-compose up -d
```

---

# ⚠️ COMMON MISTAKES

❌ Testing langsung production
❌ Tidak hapus cert staging
❌ DNS belum propagate
❌ Wildcard tanpa DNS-01

---