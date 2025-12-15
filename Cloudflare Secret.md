
## 1️⃣ Login ke Cloudflare

1. Buka **dashboard Cloudflare**
2. Login ke akun Cloudflare kamu

---

## 2️⃣ Masuk ke Menu API Tokens

1. Klik **foto profil** (pojok kanan atas)
2. Pilih **My Profile**
3. Pilih tab **API Tokens**

---

## 3️⃣ Buat API Token Baru

1. Klik **Create Token**
2. Kamu akan melihat beberapa template

---

## 4️⃣ Pilih Template (Rekomendasi)

### 🔹 Untuk SSL / DNS otomatis (acme, certbot, nginx-proxy)

Pilih:

> **Edit zone DNS**

Klik **Use template**

---

## 5️⃣ Konfigurasi Permission (PENTING)

Pastikan seperti ini:

### ✅ Permissions

| Type | Permission |
| ---- | ---------- |
| Zone | DNS → Edit |

### ✅ Zone Resources

Pilih salah satu:

* **Include → Specific zone → pilih domain kamu**
  *(lebih aman & direkomendasikan)*

atau

* **Include → All zones**
  *(jika banyak domain & trusted environment)*

📌 **Tidak perlu permission lain**

---

## 6️⃣ (Opsional) Atur TTL Token

* Bisa dikosongkan (no expiration)
* Atau set tanggal kadaluarsa jika untuk sementara

---

## 7️⃣ Create Token

1. Klik **Continue to summary**
2. Klik **Create Token**

---

## 8️⃣ SIMPAN TOKEN (WAJIB)

🚨 **Token hanya muncul SEKALI**

Contoh token:

```
CF_API_TOKEN=KJSHD8732JHD7JSHD87JHSD
```

👉 Simpan di:

* Password manager
* `.env`
* Docker secret
* CI/CD secret

---

## 9️⃣ Contoh Penggunaan (Paling Umum)

### 🔹 A. Docker + nginx-proxy + acme-companion

```bash
docker secret create cloudflare_api_token -
```

Paste token lalu `CTRL+D`

Atau `.env`:

```env
CF_API_TOKEN=xxxxxxxxxxxxxxxx
```

---

### 🔹 B. Certbot manual

```bash
export CF_API_TOKEN=xxxxxxxxxxxx
```

---

### 🔹 C. GitHub Actions / CI

Tambahkan ke **Secrets**:

```
CF_API_TOKEN
```

---

## 10️⃣ Test Token (Opsional tapi Disarankan)

```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
-H "Authorization: Bearer CF_API_TOKEN" \
-H "Content-Type: application/json"
```

Jika berhasil → status `success: true`

---

## 🔐 Best Practice Keamanan

✅ Jangan pakai **Global API Key**
✅ Gunakan **API Token minimal permission**
✅ Pisahkan token **production** & **testing**
✅ Jangan commit token ke Git

---
