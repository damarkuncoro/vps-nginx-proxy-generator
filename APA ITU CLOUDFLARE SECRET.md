
---

# 🔐 APA ITU *CLOUDFLARE SECRET*

> **Cloudflare Secret** = kredensial sensitif yang digunakan untuk **integrasi otomatis** dengan Cloudflare, **TIDAK boleh hard-coded** di repo atau image Docker.

Biasanya berupa:

* API Token
* Origin Certificate Key
* Tunnel Token
* DNS API Key (legacy – hindari)

---

# 🧱 JENIS SECRET DI CLOUDFLARE

## 1️⃣ **API TOKEN (REKOMENDASI)** ✅

Digunakan untuk:

* DNS automation (wildcard SSL)
* acme-dns challenge
* CI/CD
* Infrastructure automation

🔒 Scope bisa dibatasi → **aman**

### Contoh scope aman:

```
Zone → DNS → Edit
Zone → Zone → Read
```

---

## 2️⃣ **Global API Key** ❌ (JANGAN)

* Akses penuh akun
* Sekali bocor = tamat

👉 **Hanya untuk darurat**

---

## 3️⃣ **Origin Certificate (Cloudflare SSL)**

Digunakan jika:

* Cloudflare mode **Full (Strict)**
* SSL antara Cloudflare ↔ Origin

Biasanya:

* `origin.pem`
* `origin.key`

---

## 4️⃣ **Tunnel Token (cloudflared)**

Untuk:

* Zero-Trust Tunnel
* Tidak expose port 80/443

Contoh:

```bash
cloudflared tunnel run <TOKEN>
```

---

# 🧠 DIMANA SECRET DISIMPAN?

## ❌ JANGAN

* `.env` di repo public
* docker-compose.yml langsung
* hardcode di script

---

## ✅ OPSI AMAN (REKOMENDASI)

### 🔐 1️⃣ Docker Secret (BEST PRACTICE)

```bash
echo "CF_API_TOKEN_VALUE" | docker secret create cf_api_token -
```

Gunakan di compose:

```yaml
secrets:
  - cf_api_token

services:
  acme:
    secrets:
      - cf_api_token
```

---

### 🔐 2️⃣ `.env` (PRIVATE VPS ONLY)

```env
CF_API_TOKEN=xxxxx
```

⚠️ `.env`:

```
.gitignore
chmod 600 .env
```

---

### 🔐 3️⃣ GitHub Actions Secret

Untuk CI/CD:

```
Settings → Secrets → Actions
CF_API_TOKEN
```

---

# 🌍 CONTOH NYATA — WILDCARD SSL (DNS-01)

## Cloudflare Token Permission

```
Zone: example.com
DNS: Edit
```

---

## docker-compose acme companion (DNS-01)

```yaml
environment:
  - CF_API_TOKEN_FILE=/run/secrets/cf_api_token
  - ACME_CA_URI=https://acme-v02.api.letsencrypt.org/directory
```

Tambahkan:

```yaml
secrets:
  cf_api_token:
    file: ./secrets/cf_api_token
```

Isi file:

```bash
nano secrets/cf_api_token
```

```
xxxxxxxxxxxxxxxxxxxx
```

---

## Container APP (Wildcard)

```yaml
environment:
  - VIRTUAL_HOST=*.example.com
  - LETSENCRYPT_HOST=*.example.com
  - LETSENCRYPT_DNS_PROVIDER=cloudflare
```

🎉 **Satu sertifikat → semua subdomain**

---

# 🔁 STAGING / DRY-RUN MODE

```yaml
environment:
  - ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
```

Gunakan **staging dulu** → hindari rate limit.

---

# 🔄 AUTO RENEW + AUTO SWITCH

acme-companion:

* auto renew
* reload nginx otomatis
* **zero downtime**

Tidak perlu cron.

---

# 🔐 SUPABASE + CLOUDFLARE SECRET

### Gunakan untuk:

* JWT signing
* Webhook signature
* Edge function secret

Contoh:

```env
SUPABASE_JWT_SECRET=xxxx
```

Di Supabase:

```
Settings → Secrets
```

---

# 🚨 SECURITY CHECKLIST (WAJIB)

| Item                | Status |
| ------------------- | ------ |
| API Token scoped    | ✅      |
| No Global API Key   | ✅      |
| Secret outside repo | ✅      |
| File permission 600 | ✅      |
| Staging before prod | ✅      |

---
