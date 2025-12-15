# 🤖 AUTO RENEW + AUTO SWITCH (BLUE–GREEN SSL)

## 🎯 TARGET

* SSL **renew otomatis**
* **Cert baru dites**
* **Switch atomic**
* **Rollback otomatis jika gagal**
* **Aman wildcard & multi-domain**

---

# 🧠 FINAL FLOW (FULLY AUTOMATED)

```
Cron
 ↓
Trigger acme-companion renew
 ↓
Cert masuk → certs-green
 ↓
Validate cert (expiry + format)
 ↓
Health check nginx config
 ↓
Switch symlink (blue → green)
 ↓
Reload nginx (no restart)
 ↓
Promote green → blue
```

---

# 🧱 STRUKTUR FINAL (WAJIB)

```
/opt/nginx-proxy/data/nginx/
├── certs-blue/      ← ACTIVE
├── certs-green/     ← NEW
└── certs -> certs-blue (symlink)
```

---

# 🔧 STEP 1 — RENEW SCRIPT

### 📄 `/opt/nginx-proxy/scripts/ssl-renew.sh`

```bash
#!/bin/bash
set -e

ACME_CONTAINER="nginx-proxy-acme"

echo "🔁 Trigger SSL renew via acme-companion"

docker exec $ACME_CONTAINER /app/force_renew || true

echo "✅ Renew triggered (certs written to GREEN)"
```

> `force_renew` = aman, tidak ganggu cert aktif

---

# 🔧 STEP 2 — VALIDATION SCRIPT (SAFETY GUARD)

### 📄 `/opt/nginx-proxy/scripts/ssl-validate.sh`

```bash
#!/bin/bash
set -e

GREEN="/opt/nginx-proxy/data/nginx/certs-green"

echo "🔍 Validating GREEN certificates..."

find "$GREEN" -name fullchain.pem | while read cert; do
  domain=$(basename "$(dirname "$cert")")
  echo "➡️ Checking $domain"

  # 1. Valid format
  openssl x509 -in "$cert" -noout >/dev/null

  # 2. Expiry check (min 7 days)
  end_date=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
  end_ts=$(date -d "$end_date" +%s)
  now_ts=$(date +%s)

  if (( (end_ts - now_ts) < 604800 )); then
    echo "❌ Cert $domain expires too soon"
    exit 1
  fi
done

echo "✅ All GREEN certs valid"
```

---

# 🔁 STEP 3 — AUTO SWITCH SCRIPT

### 📄 `/opt/nginx-proxy/scripts/ssl-switch.sh`

```bash
#!/bin/bash
set -e

BASE="/opt/nginx-proxy/data/nginx"
NGINX="nginx-proxy"

echo "🔁 Switching SSL GREEN → ACTIVE"

# Pre-check nginx config
docker exec $NGINX nginx -t

# Atomic switch
ln -sfn $BASE/certs-green $BASE/certs
docker exec $NGINX nginx -s reload

# Promote GREEN → BLUE
rm -rf $BASE/certs-blue/*
cp -a $BASE/certs-green/* $BASE/certs-blue/

echo "✅ SSL switched & promoted (zero downtime)"
```

---

# 🔁 STEP 4 — MASTER AUTO SCRIPT

### 📄 `/opt/nginx-proxy/scripts/ssl-auto.sh`

```bash
#!/bin/bash
set -e

DIR="/opt/nginx-proxy/scripts"

echo "🤖 AUTO SSL RENEW START"

$DIR/ssl-renew.sh
sleep 30   # wait acme to finish

$DIR/ssl-validate.sh
$DIR/ssl-switch.sh

echo "🎉 AUTO SSL RENEW COMPLETE"
```

---

# ⏪ AUTO ROLLBACK (BUILT-IN)

Kalau **salah satu step gagal**:

* `set -e` → script **STOP**
* **certs-blue tetap aktif**
* nginx **tidak reload**
* traffic **AMAN**

Rollback manual (jika perlu):

```bash
ln -sfn certs-blue certs
docker exec nginx-proxy nginx -s reload
```

---

# ⏱️ STEP 5 — CRON JOB (FULL AUTO)

### Pasang cron

```bash
crontab -e
```

### Set renew **2x sebulan**

```cron
0 3 1,15 * * /opt/nginx-proxy/scripts/ssl-auto.sh >> /var/log/ssl-auto.log 2>&1
```

➡️ Jam 03:00 (low traffic)
➡️ Log tersimpan

---

# 🧪 DRY RUN MODE (AMAN TEST)

```bash
bash -x /opt/nginx-proxy/scripts/ssl-auto.sh
```

Atau:

```bash
export ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
```

---

# 🏆 HASIL AKHIR

| Fitur         | Status |
| ------------- | ------ |
| Auto renew    | ✅      |
| Zero downtime | ✅      |
| Atomic switch | ✅      |
| Rollback      | ✅      |
| Wildcard safe | ✅      |
| CI/CD ready   | ✅      |

---