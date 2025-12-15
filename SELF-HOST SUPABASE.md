
---

# 🧠 KONSEP SELF-HOST SUPABASE

Supabase = kumpulan service:

| Komponen   | Fungsi         |
| ---------- | -------------- |
| PostgreSQL | Database utama |
| GoTrue     | Auth           |
| PostgREST  | REST API       |
| Realtime   | WebSocket      |
| Storage    | File           |
| Kong       | API Gateway    |
| Studio     | Admin UI       |

👉 Semua **Docker-based**, **bisa private**, **data tidak keluar VPS**
👉 Cocok dengan filosofi kamu: **self-host, auditabel, modular**

---

# 🧱 ARSITEKTUR (DENGAN nginx-proxy)

```
Internet
  │
HTTPS (nginx-proxy)
  │
supabase.domain.com
  │
Kong (API Gateway)
  │
┌───────────────┬───────────────┐
│ Postgres      │ Auth / Storage│
└───────────────┴───────────────┘
```

---

# ✅ REQUIREMENT

| Item   | Minimal                 |
| ------ | ----------------------- |
| OS     | Ubuntu 20.04 / 22.04    |
| RAM    | 4 GB (8 GB recommended) |
| Docker | ✅                       |
| Domain | api.example.com         |
| SSL    | dari nginx-proxy        |

---

# 📁 STEP 1 — CLONE SUPABASE DOCKER

```bash
cd /opt
git clone https://github.com/supabase/supabase.git
cd supabase/docker
```

Copy env:

```bash
cp .env.example .env
```

---

# 🔐 STEP 2 — EDIT `.env` (WAJIB)

```bash
nano .env
```

### MINIMAL YANG HARUS DIGANTI

```env
POSTGRES_PASSWORD=supersecretpassword
JWT_SECRET=superjwtsecret
SITE_URL=https://supabase.example.com
API_EXTERNAL_URL=https://supabase.example.com
```

> ⚠️ **JWT_SECRET jangan bocor**

---

# 🌍 STEP 3 — DOMAIN & SSL (nginx-proxy)

Supabase **TIDAK expose port ke publik**, hanya lewat proxy.

Tambahkan ke `docker-compose.yml` Supabase (service `kong`):

```yaml
environment:
  - VIRTUAL_HOST=supabase.example.com
  - LETSENCRYPT_HOST=supabase.example.com
  - LETSENCRYPT_EMAIL=admin@example.com
networks:
  - proxy
```

Dan pastikan:

```yaml
networks:
  proxy:
    external: true
```

---

# ▶️ STEP 4 — JALANKAN SUPABASE

```bash
docker compose up -d
```

Cek:

```bash
docker ps
```

Service utama:

* kong
* auth
* rest
* realtime
* storage
* postgres

---

# 🖥️ STEP 5 — AKSES SUPABASE STUDIO

```
https://supabase.example.com
```

Login:

* email: bebas (admin pertama)
* password: buat sendiri

🎉 **Supabase self-host siap**

---

# 🔑 STEP 6 — API KEY

Di Studio → Settings → API

Ambil:

* `anon public key`
* `service_role key`

Gunakan seperti Supabase Cloud:

```js
createClient(
  "https://supabase.example.com",
  "anon_key"
)
```

---

# 🔐 SECURITY WAJIB (JANGAN LEWAT)

### 1️⃣ Aktifkan Row Level Security (RLS)

```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

### 2️⃣ Jangan expose service_role ke frontend

### 3️⃣ Firewall

```bash
ufw allow 80
ufw allow 443
ufw deny 5432
```

---

# 💾 BACKUP DATABASE (WAJIB)

```bash
docker exec supabase-db \
  pg_dump -U postgres postgres > supabase.sql
```

(ini bisa kamu gabungkan dengan sistem backup otomatis kamu sebelumnya)

---

# 🧪 MODE STAGING / DEV

Tambahkan subdomain:

```
supabase-dev.example.com
```

Clone `.env` → ganti `SITE_URL`

---

# ⚠️ HAL YANG SERING SALAH

❌ Supabase expose port langsung
❌ JWT_SECRET default
❌ Tidak pakai RLS
❌ Database tanpa backup
❌ Public service_role key

---

# 🏆 KAPAN SELF-HOST SUPABASE TEPAT?

| Use Case           | Cocok                 |
| ------------------ | --------------------- |
| Data sensitif      | ✅                     |
| On-prem / koperasi | ✅                     |
| Audit & compliance | ✅                     |
| Startup cepat      | ❌ (cloud lebih cepat) |

---
