# 📧 MEMBUAT MAIL SERVER (PRODUCTION)

## 🔴 PENTING (BACA DULU)

Mail server **bukan seperti web server**:

* ❌ Salah config → **email masuk SPAM**
* ❌ IP jelek → **ditolak Gmail**
* ❌ Kurang DNS → **mail tidak terkirim**

Makanya **pilihan arsitektur itu KRUSIAL**.

---

# 🧭 PILIHAN ARSITEKTUR (JUJUR & REALISTIS)

## 🥇 OPSI 1 — **Mailcow (REKOMENDASI KERAS)** ✅

> Docker-based, battle-tested, dipakai ISP & perusahaan

✔️ SPF, DKIM, DMARC
✔️ Anti-spam, anti-virus
✔️ Webmail (SOGo)
✔️ Auto TLS
✔️ Admin UI
✔️ Cocok dengan VPS kamu

👉 **INI YANG AKU CONTOHKAN DI BAWAH**

---

## 🥈 OPSI 2 — Postfix + Dovecot Manual

✔️ Lebih ringan
❌ RIBET
❌ Banyak jebakan
❌ Maintenance berat

👉 Cocok kalau kamu mau **belajar**, bukan produksi cepat.

---

# 🏗️ ARSITEKTUR MAILCOW

```
Internet
  │
SMTP / IMAP / HTTPS
  │
[ Mailcow Docker Stack ]
  │
Mail Storage
```

> ⚠️ **Mail server TIDAK lewat nginx-proxy**
> (port mail harus direct)

---

# 🧱 STEP 0 — SYARAT WAJIB

### VPS

* Ubuntu 20.04 / 22.04
* RAM **minimal 2GB** (4GB recommended)
* IP publik **TIDAK BLACKLIST**

### Domain

Contoh:

```
mail.example.com
```

---

# 🌍 STEP 1 — DNS RECORD (WAJIB SEMUA)

### A Record

```
mail.example.com → IP_VPS
```

### MX Record

```
example.com → mail.example.com (prio 10)
```

### SPF

```
Type: TXT
Name: @
Value: v=spf1 ip4:IP_VPS -all
```

### DMARC

```
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com
```

DKIM → **auto dibuat Mailcow**

---

# 🐳 STEP 2 — INSTALL MAILCOW

```bash
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized.git
cd mailcow-dockerized
```

Generate config:

```bash
./generate_config.sh
```

Isi:

```
Mail server hostname: mail.example.com
Timezone: Asia/Jakarta
```

---

# 🔐 STEP 3 — JALANKAN MAIL SERVER

```bash
docker compose pull
docker compose up -d
```

Cek:

```bash
docker ps
```

---

# 🖥️ STEP 4 — LOGIN ADMIN PANEL

Buka:

```
https://mail.example.com
```

Default:

```
user: admin
pass: moohoo
```

👉 **WAJIB GANTI PASSWORD**

---

# ✉️ STEP 5 — BUAT EMAIL

### Admin Panel:

1. Domains → Add domain

   ```
   example.com
   ```
2. Mailboxes → Add mailbox

   ```
   admin@example.com
   ```

---

# 🔑 STEP 6 — SET DKIM (PENTING!)

Admin Panel → Configuration → DKIM

Copy record → tambah ke DNS:

```
default._domainkey.example.com
```

Tunggu ±1 menit → klik **Verify DKIM**

---

# 🧪 STEP 7 — TEST EMAIL

### Test keluar

Kirim ke:

```
gmail.com
```

### Test masuk

Kirim dari Gmail ke:

```
admin@example.com
```

---

# 🧪 STEP 8 — CEK SCORE SPAM

Gunakan:

* [https://www.mail-tester.com](https://www.mail-tester.com)
* [https://mxtoolbox.com](https://mxtoolbox.com)

Target:

* ✅ SPF PASS
* ✅ DKIM PASS
* ✅ DMARC PASS

---

# 🔐 PORT YANG HARUS DIBUKA

```bash
ufw allow 25
ufw allow 465
ufw allow 587
ufw allow 993
ufw allow 995
```

---

# ⚠️ HAL YANG SERING BIKIN GAGAL

❌ PTR / rDNS belum diset
❌ IP VPS blacklist
❌ SPF salah
❌ Cloudflare proxy ON (HARUS OFF)
❌ Port 25 diblok provider

---

# 🧠 BEST PRACTICE (JUJUR)

| Kebutuhan             | Rekomendasi        |
| --------------------- | ------------------ |
| Email internal / SaaS | Mailcow            |
| Email marketing       | ❌ JANGAN self-host |
| Reliability tinggi    | Mailcow + backup   |
| Simple                | Zoho / Google      |

---

# 🧠 INTEGRASI DENGAN SISTEM KAMU

Mail server ini bisa:

* Dipakai Supabase auth
* Dipakai SaaS kamu
* Dipakai notifikasi sistem
* Dipakai SMTP relay internal

---
