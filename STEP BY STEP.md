Siap. Kita buat **STEP-BY-STEP PALING DETAIL & REAL WORLD**
📌 **3 DOMAIN BERBEDA**
📌 **MASING-MASING DI CLOUDFLARE BERBEDA (AKUN / ZONE BERBEDA)**
📌 **1 VPS – 1 reverse proxy – SSL otomatis – rapi – scalable**

Domain:

* `tahubulat.com`
* `kacanggoreng.com`
* `papapulang.com`

---

# 🧠 PRINSIP UTAMA (JANGAN DILANGGAR)

1. **HANYA 1 nginx-proxy di VPS**
2. **Setiap domain berdiri sendiri**
3. **DNS Cloudflare boleh beda akun**
4. **Token Cloudflare = multi-zone**
5. **Semua container masuk network `proxy`**
6. **Tidak ada port expose selain 80/443**

---

# 🧱 FINAL ARSITEKTUR

```
Internet
   │
Cloudflare (akun A / B / C)
   │
nginx-proxy + acme (VPS)
   │
Docker network: proxy
   │
┌───────────────┬───────────────┬───────────────┐
│ tahubulat.com │ kacanggoreng  │ papapulang   │
│ containers    │ containers    │ containers    │
└───────────────┴───────────────┴───────────────┘
```

---

# 🔰 STEP 0 — SYARAT AWAL

✔ VPS Ubuntu 20.04 / 22.04
✔ IP publik (misal `103.xxx.xxx.xxx`)
✔ 3 domain aktif
✔ Akses root / sudo

---

# 🔐 STEP 1 — LOGIN & UPDATE VPS

```bash
ssh root@IP_VPS
```

```bash
apt update && apt upgrade -y
```

Install tool dasar:

```bash
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  nano \
  ufw
```

---

# 🐳 STEP 2 — INSTALL DOCKER

```bash
curl -fsSL https://get.docker.com | bash
```

Aktifkan:

```bash
systemctl enable docker
systemctl start docker
```

Cek:

```bash
docker --version
```

---

# 📦 STEP 3 — INSTALL DOCKER COMPOSE

```bash
apt install -y docker-compose
```

```bash
docker-compose --version
```

---

# 🌐 STEP 4 — BUAT NETWORK GLOBAL (WAJIB)

⚠️ **HANYA SEKALI**

```bash
docker network create proxy
```

Cek:

```bash
docker network ls
```

---

# 📁 STEP 5 — STRUKTUR FOLDER VPS (FINAL)

```bash
mkdir -p /opt/{proxy,domains,shared}
```

```text
/opt
├── proxy
│   ├── docker-compose.yml
│   ├── secrets/
│   │   ├── cf_tahubulat
│   │   ├── cf_kacanggoreng
│   │   └── cf_papapulang
│   └── data/nginx/
│       ├── certs/
│       ├── vhost.d/
│       └── html/
│
├── domains
│   ├── tahubulat.com/
│   │   └── app/
│   ├── kacanggoreng.com/
│   │   └── web/
│   └── papapulang.com/
│       └── site/
│
└── shared
    └── backup/
```

🧠 **1 domain = 1 folder**
🧠 **1 subdomain = 1 docker-compose**

---

# 🔑 STEP 6 — CLOUDflare API TOKEN (PER DOMAIN)

## 6.1 Tahubulat.com (Akun CF #1)

Buat token:

* Zone → tahubulat.com
* DNS → Edit
* Zone → Read

Simpan:

```bash
nano /opt/proxy/secrets/cf_tahubulat
chmod 600 /opt/proxy/secrets/cf_tahubulat
```

---

## 6.2 Kacanggoreng.com (Akun CF #2)

```bash
nano /opt/proxy/secrets/cf_kacanggoreng
chmod 600 /opt/proxy/secrets/cf_kacanggoreng
```

---

## 6.3 Papapulang.com (Akun CF #3)

```bash
nano /opt/proxy/secrets/cf_papapulang
chmod 600 /opt/proxy/secrets/cf_papapulang
```

---

# 🧱 STEP 7 — GLOBAL nginx-proxy + acme

📂 `/opt/proxy/docker-compose.yml`

```yaml
version: "3.8"

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

  acme:
    image: nginxproxy/acme-companion
    container_name: nginx-proxy-acme
    restart: always
    depends_on:
      - nginx-proxy
    environment:
      - DEFAULT_EMAIL=admin@server.local
    volumes:
      - ./data/nginx/certs:/etc/nginx/certs
      - ./data/nginx/vhost.d:/etc/nginx/vhost.d
      - ./data/nginx/html:/usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy
    secrets:
      - cf_tahubulat
      - cf_kacanggoreng
      - cf_papapulang

networks:
  proxy:
    external: true

secrets:
  cf_tahubulat:
    file: ./secrets/cf_tahubulat
  cf_kacanggoreng:
    file: ./secrets/cf_kacanggoreng
  cf_papapulang:
    file: ./secrets/cf_papapulang
```

---

# ▶️ STEP 8 — JALANKAN PROXY

```bash
cd /opt/proxy
docker-compose up -d
```

Cek:

```bash
docker ps
```

✔ nginx-proxy
✔ nginx-proxy-acme

---

# 🌍 STEP 9 — DNS SETIAP DOMAIN (PENTING)

## Tahubulat.com (Cloudflare A)

```
A tahubulat.com        → IP_VPS
A *.tahubulat.com      → IP_VPS
```

## Kacanggoreng.com (Cloudflare B)

```
A kacanggoreng.com     → IP_VPS
A *.kacanggoreng.com   → IP_VPS
```

## Papapulang.com (Cloudflare C)

```
A papapulang.com      → IP_VPS
A *.papapulang.com    → IP_VPS
```

Cloudflare:

* Proxy ON (orange)
* SSL Mode: **Full (Strict)**

---

# 🚀 STEP 10 — DOMAIN 1: tahubulat.com

```bash
mkdir -p /opt/domains/tahubulat.com/app
cd /opt/domains/tahubulat.com/app
```

```yaml
version: "3.8"

services:
  web:
    image: nginx
    environment:
      - VIRTUAL_HOST=app.tahubulat.com
      - LETSENCRYPT_HOST=app.tahubulat.com
      - LETSENCRYPT_DNS_PROVIDER=cloudflare
      - CF_API_TOKEN_FILE=/run/secrets/cf_tahubulat
    networks:
      - proxy

networks:
  proxy:
    external: true
```

```bash
docker-compose up -d
```

---

# 🚀 STEP 11 — DOMAIN 2: kacanggoreng.com

```bash
mkdir -p /opt/domains/kacanggoreng.com/web
cd /opt/domains/kacanggoreng.com/web
```

```yaml
services:
  web:
    image: nginx
    environment:
      - VIRTUAL_HOST=www.kacanggoreng.com
      - LETSENCRYPT_HOST=www.kacanggoreng.com
      - LETSENCRYPT_DNS_PROVIDER=cloudflare
      - CF_API_TOKEN_FILE=/run/secrets/cf_kacanggoreng
    networks:
      - proxy
```

```bash
docker-compose up -d
```

---

# 🚀 STEP 12 — DOMAIN 3: papapulang.com

```bash
mkdir -p /opt/domains/papapulang.com/site
cd /opt/domains/papapulang.com/site
```

```yaml
services:
  web:
    image: nginx
    environment:
      - VIRTUAL_HOST=papapulang.com
      - LETSENCRYPT_HOST=papapulang.com
      - LETSENCRYPT_DNS_PROVIDER=cloudflare
      - CF_API_TOKEN_FILE=/run/secrets/cf_papapulang
    networks:
      - proxy
```

```bash
docker-compose up -d
```

---

# 🔐 STEP 13 — FIREWALL

```bash
ufw allow 22
ufw allow 80
ufw allow 443
ufw enable
```

---

# ✅ HASIL AKHIR

✔ 1 VPS
✔ 3 domain
✔ 3 Cloudflare akun
✔ SSL otomatis
✔ Tidak konflik
✔ Tinggal copy-paste domain baru

---

Siap. Ini **MAIL SERVER MULTI-DOMAIN — STEP BY STEP PALING DETAIL (PRODUKSI)**
📌 **1 VPS**
📌 **Banyak domain** (`tahubulat.com`, `kacanggoreng.com`, `papapulang.com`)
📌 **SSL otomatis**
📌 **SPF, DKIM, DMARC lengkap**
📌 **Backup otomatis**
📌 **Terintegrasi dengan nginx-proxy stack kamu**

Kita pakai **docker-mailserver** (paling stabil & battle-tested).

---

# 🎯 TARGET AKHIR

| Domain           | Email                                                   |
| ---------------- | ------------------------------------------------------- |
| tahubulat.com    | [admin@tahubulat.com](mailto:admin@tahubulat.com)       |
| kacanggoreng.com | [hello@kacanggoreng.com](mailto:hello@kacanggoreng.com) |
| papapulang.com   | [info@papapulang.com](mailto:info@papapulang.com)       |

Semua:

* SMTP (587)
* IMAP (993)
* SSL valid
* Bisa Gmail / Outlook
* Bisa backup & restore

---

# 🧠 ARSITEKTUR MAIL

```
Mail Client (Gmail / Outlook)
   │
SMTP / IMAP (SSL)
   │
docker-mailserver
   │
Maildir (Volume)
```

👉 **Mail server TIDAK lewat nginx-proxy**
👉 Mail pakai **port sendiri** (SMTP/IMAP)

---

# 🧱 STEP 0 — PERSIAPAN VPS

Pastikan:

* Port terbuka:

  * 25 (optional)
  * 587 (SMTP submission)
  * 993 (IMAPS)

```bash
ufw allow 25
ufw allow 587
ufw allow 993
```

---

# REFERENSI

* 
* [https://github.com/docker-mailserver/docker-mailserver/wiki](https://github.com/docker-mailserver/docker-mailserver/wiki)


# 📁 STEP 1 — STRUKTUR FOLDER MAIL

```bash
mkdir -p /opt/mail
cd /opt/mail
```

Struktur final:

```
/opt/mail
├── docker-compose.yml
├── maildata/
├── mailstate/
├── maillogs/
├── config/
└── backups/
```

---

# 🐳 STEP 2 — docker-compose.yml

```bash
nano docker-compose.yml
```

```yaml
version: "3.8"

services:
  mailserver:
    image: docker.io/mailserver/docker-mailserver:latest
    container_name: mailserver
    hostname: mail
    domainname: server.local
    restart: always
    ports:
      - "25:25"
      - "587:587"
      - "993:993"
    volumes:
      - ./maildata:/var/mail
      - ./mailstate:/var/mail-state
      - ./maillogs:/var/log/mail
      - ./config:/tmp/docker-mailserver
      - /etc/localtime:/etc/localtime:ro
    environment:
      - ENABLE_SPAMASSASSIN=1
      - ENABLE_CLAMAV=1
      - ENABLE_FAIL2BAN=1
      - ENABLE_POSTGREY=1
      - ONE_DIR=1
      - SSL_TYPE=letsencrypt
    cap_add:
      - NET_ADMIN
      - SYS_PTRACE
```

---

# ▶️ STEP 3 — JALANKAN MAIL SERVER

```bash
docker-compose up -d
```

Cek:

```bash
docker ps
```

---

# 👤 STEP 4 — BUAT AKUN EMAIL

Format:

```bash
docker exec -it mailserver setup email add email@domain.com password
```

### Contoh:

```bash
docker exec -it mailserver setup email add admin@tahubulat.com StrongPass123
docker exec -it mailserver setup email add hello@kacanggoreng.com StrongPass123
docker exec -it mailserver setup email add info@papapulang.com StrongPass123
```

Cek akun:

```bash
docker exec -it mailserver setup email list
```

---

# 🌍 STEP 5 — DNS RECORD SETIAP DOMAIN (WAJIB)

## 🔹 MX RECORD

| Type | Name | Value           | Priority |
| ---- | ---- | --------------- | -------- |
| MX   | @    | mail.domain.com | 10       |

---

## 🔹 A RECORD

```
mail.tahubulat.com     → IP_VPS
mail.kacanggoreng.com  → IP_VPS
mail.papapulang.com   → IP_VPS
```

---

## 🔐 STEP 6 — SPF

```dns
Type: TXT
Name: @
Value: v=spf1 mx ip4:IP_VPS -all
```

---

## ✍️ STEP 7 — DKIM

Generate DKIM:

```bash
docker exec -it mailserver setup config dkim
```

Ambil public key:

```bash
cat /opt/mail/config/opendkim/keys/*/mail.txt
```

Tambahkan ke DNS:

```dns
Type: TXT
Name: mail._domainkey
Value: v=DKIM1; k=rsa; p=MIIBIjANBgkq...
```

(Per domain → beda key)

---

## 🛡️ STEP 8 — DMARC

```dns
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:postmaster@domain.com; ruf=mailto:postmaster@domain.com; fo=1
```

---

# 🔒 STEP 9 — SSL MAIL

docker-mailserver:

* Auto pakai Let’s Encrypt
* Renew otomatis
* Tidak perlu manual

Cek:

```bash
openssl s_client -connect mail.domain.com:993
```

---

# 💾 STEP 10 — BACKUP OTOMATIS MAIL

Buat script:

```bash
nano /opt/mail/backup.sh
```

```bash
#!/bin/bash
tar czf /opt/mail/backups/mail-$(date +%F).tar.gz /opt/mail/maildata
```

```bash
chmod +x /opt/mail/backup.sh
```

Cron:

```bash
crontab -e
```

```cron
0 2 * * * /opt/mail/backup.sh
```

---

# 🧪 STEP 11 — TEST KIRIM & TERIMA

Test SMTP:

```bash
swaks --to test@gmail.com --from admin@tahubulat.com --server mail.tahubulat.com
```

Test login IMAP:

* Gmail → Add account
* IMAP:

  * Server: mail.domain.com
  * Port: 993
  * SSL: ON

---

# 🚨 KESALAHAN FATAL (JANGAN)

❌ Tanpa SPF
❌ Tanpa DKIM
❌ Tanpa DMARC
❌ Open relay
❌ Backup manual

---

# 🏁 HASIL AKHIR

✔ Multi-domain mail server
✔ SSL valid
✔ Gmail friendly
✔ Backup otomatis
✔ Siap produksi

---


# 📚 REFERENSI

* [https://github.com/docker-mailserver/docker-mailserver](https://github.com/docker-mailserver/docker-mailserver)
* [https://github.com/docker-mailserver/docker-mailserver/wiki](https://github.com/docker-mailserver/docker-mailserver/wiki)