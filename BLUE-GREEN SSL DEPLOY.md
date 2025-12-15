# 🔵🟢 APA ITU BLUE-GREEN SSL DEPLOY

Tujuan:

* **Generate / renew SSL TANPA ganggu traffic**
* **Rollback cepat** kalau cert gagal
* Aman untuk **wildcard + multi-domain**

---

## 🧠 MASALAH KLASIK (tanpa blue-green)

❌ Replace cert langsung
❌ nginx reload → error cert
❌ downtime
❌ browser error

---

## ✅ SOLUSI BLUE-GREEN

```
CERT ACTIVE  →  CERT BARU (TEST)
   (BLUE)        (GREEN)
      │              │
      └── switch atomic ──►
```

➡️ nginx **tidak pernah** pegang cert setengah jadi

---

# 🧱 ARSITEKTUR BLUE-GREEN SSL

```
/opt/nginx-proxy/data/nginx/
├── certs-blue/     ← ACTIVE
├── certs-green/    ← NEW / TEST
└── certs/          ← SYMLINK → blue atau green
```

nginx **hanya baca**:

```
certs → certs-blue OR certs-green
```

---

# 🔧 STEP 1 — SETUP STRUKTUR CERT

```bash
cd /opt/nginx-proxy/data/nginx

mkdir certs-blue certs-green

# Default aktif BLUE
ln -sfn certs-blue certs
```

---

# 🔧 STEP 2 — UPDATE docker-compose (nginx-proxy)

### nginx-proxy

```yaml
volumes:
  - ./data/nginx/certs:/etc/nginx/certs
```

👉 **Tetap sama**, karena certs adalah symlink

---

### acme-companion (issue cert ke GREEN)

```yaml
volumes:
  - ./data/nginx/certs-green:/etc/nginx/certs
```

👉 Ini **KRUSIAL**
➡️ acme menulis cert ke **GREEN**, bukan ACTIVE

---

## 🧩 Hasil mapping

| Container      | Cert path    |
| -------------- | ------------ |
| nginx-proxy    | certs → blue |
| acme-companion | certs-green  |

---

# 🧪 STEP 3 — ISSUE / RENEW SSL (GREEN)

```bash
docker logs nginx-proxy-acme
```

Tunggu:

```
Successfully received certificate.
```

➡️ **Traffic masih pakai cert BLUE**

---

# 🔍 STEP 4 — VALIDASI GREEN CERT

```bash
ls certs-green/example.com/
```

Cek:

* `fullchain.pem`
* `privkey.pem`

Optional test:

```bash
openssl x509 -in certs-green/example.com/fullchain.pem -noout -dates
```

---

# 🔁 STEP 5 — SWITCH BLUE → GREEN (ATOMIC)

```bash
cd /opt/nginx-proxy/data/nginx

ln -sfn certs-green certs
docker exec nginx-proxy nginx -s reload
```

⚡ **Instant**
⚡ **No downtime**
⚡ **No container restart**

---

# ⏪ ROLLBACK (1 COMMAND)

Kalau ada error:

```bash
ln -sfn certs-blue certs
docker exec nginx-proxy nginx -s reload
```

➡️ **Traffic balik ke cert lama**

---

# 🔁 STEP 6 — PROMOTE GREEN → BLUE

Kalau sudah yakin:

```bash
rm -rf certs-blue/*
cp -a certs-green/* certs-blue/
```

➡️ GREEN jadi baseline baru

---

# 🧠 FLOW PRODUKSI (REKOMENDASI)

```
Issue cert → GREEN
      ↓
Verify
      ↓
Switch symlink
      ↓
Reload nginx
      ↓
Cleanup
```

---

# 🤖 AUTO SCRIPT (1 COMMAND)

### `ssl-blue-green-switch.sh`

```bash
#!/bin/bash
set -e

BASE="/opt/nginx-proxy/data/nginx"

echo "🔁 Switching GREEN → ACTIVE"

ln -sfn $BASE/certs-green $BASE/certs
docker exec nginx-proxy nginx -s reload

echo "✅ SSL switched with zero downtime"
```

---

# ⚠️ HAL YANG WAJIB DIPATUHI

❌ Jangan mount certs-green ke nginx
❌ Jangan hapus cert-blue sebelum switch sukses
❌ Jangan restart nginx-proxy (reload saja)
❌ Jangan campur staging & prod cert

---

# 🏆 KEUNTUNGAN NYATA

✔️ Zero downtime
✔️ Rollback instan
✔️ Aman untuk wildcard
✔️ Cocok CI/CD
✔️ Enterprise-grade

---
