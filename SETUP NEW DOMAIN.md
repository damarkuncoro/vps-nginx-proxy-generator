

# 🧩 SKENARIO CONTOH

Misal kamu mau tambah domain baru:

```
app.barucontoh.com
```

Kondisi:

* VPS sudah running nginx-proxy stack
* Domain `barucontoh.com` sudah di Cloudflare
* SSL wildcard atau multi-domain tersedia

---

# 1️⃣ SET DNS (WAJIB)

Di **Cloudflare → DNS**:

### Jika pakai wildcard (`*.barucontoh.com`)

```
Type : A
Name : *
IP   : IP_VPS
Proxy: OFF (abu-abu)
```

### Jika non-wildcard

```
Type : A
Name : app
IP   : IP_VPS
Proxy: OFF
```

Tunggu DNS propagate (±1 menit).

---

# 2️⃣ BUAT APP DOMAIN BARU (1 COMMAND)

```bash
sudo ./scripts/app-generator.sh
```

Isi prompt:

```
🌍 Domain (example.com): app.barucontoh.com
📧 SSL Email: admin@barucontoh.com
```

👉 Script otomatis:

* Buat folder `/opt/apps/app.barucontoh.com`
* Generate `docker-compose.yml`
* Join network `proxy`
* Trigger acme-companion (GREEN cert)

---

# 3️⃣ CEK PROSES SSL (GREEN)

```bash
docker logs nginx-proxy-acme
```

Output sukses:

```
Successfully received certificate.
```

Cert tersimpan di:

```
/opt/nginx-proxy/data/nginx/certs-green/app.barucontoh.com/
```

---

# 4️⃣ VALIDASI CERT BARU

```bash
openssl x509 \
  -in /opt/nginx-proxy/data/nginx/certs-green/app.barucontoh.com/fullchain.pem \
  -noout -dates
```

Pastikan:

* NotBefore: hari ini
* NotAfter: +90 hari

---

# 5️⃣ AUTO SWITCH SSL (ZERO DOWNTIME)

```bash
sudo /opt/nginx-proxy/scripts/ssl-auto.sh
```

Yang terjadi:

* Validasi cert GREEN
* Switch symlink
* nginx reload (tanpa restart)
* Promote cert → BLUE

---

# 6️⃣ AKSES DOMAIN

Buka browser:

```
https://app.barucontoh.com
```

✔️ HTTPS valid
✔️ Tidak ada downtime
✔️ Domain lama tetap aman

---

# 🧠 JIKA PAKAI WILDCARD

Kalau kamu **sudah punya**:

```
*.barucontoh.com
```

Maka langkah 2–5 **bahkan TIDAK PERLU** SSL lagi.

Cukup:

```bash
sudo ./scripts/app-generator.sh
```

Dan domain langsung HTTPS karena:

* Cert wildcard sudah aktif di BLUE

---

# 🧪 MODE TESTING (AMAN)

Kalau mau test dulu:

```bash
sudo ./scripts/app-generator-dry.sh
```

Akses:

```
http://app.barucontoh.com
```

---

# ⚠️ ERROR YANG SERING TERJADI

| Error           | Penyebab                  |
| --------------- | ------------------------- |
| SSL pending     | DNS belum resolve         |
| 502 Bad Gateway | App container mati        |
| HTTP only       | LETSENCRYPT_* belum diset |
| cert gagal      | Cloudflare token salah    |

---

# 🏆 RINGKASAN (1 DOMAIN BARU)

```
DNS → run script → wait → auto switch → DONE
```

⏱️ Waktu total: **< 2 menit**

---
