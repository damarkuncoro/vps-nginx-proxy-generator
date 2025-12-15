# 💾 STRATEGI BACKUP MAIL (BEST PRACTICE)

## 🎯 TARGET

* Backup **email + config + database**
* Jalan **otomatis**
* **Encrypted**
* Bisa restore:

  * 1 mailbox
  * 1 domain
  * Full system

---

# 🧠 ARSITEKTUR BACKUP

```
Mailcow Containers
   │
Volumes (maildir, mysql, redis, config)
   │
Backup Script
   │
Encrypted Archive (.tar.gz.enc)
   │
┌───────────────┬───────────────┐
│ Local Disk    │ Remote (S3 /  │
│ /backup/mail  │ rsync / rclone│
└───────────────┴───────────────┘
```

---

# 📦 APA SAJA YANG DIBACKUP (WAJIB)

| Komponen    | Path           |
| ----------- | -------------- |
| Mail data   | `./data/vmail` |
| MySQL       | `mysql dump`   |
| Config      | `mailcow.conf` |
| DKIM keys   | `./data/dkim`  |
| Sieve rules | `./data/sieve` |

---

# 📁 STRUKTUR BACKUP

```
/backup/mailcow/
├── daily/
│   └── mailcow-2025-01-15.tar.gz.enc
├── weekly/
└── monthly/
```

---

# 🔐 STEP 1 — BUAT BACKUP SCRIPT

### 📄 `/opt/mailcow-dockerized/scripts/backup-mailcow.sh`

```bash
#!/bin/bash
set -e

BASE="/opt/mailcow-dockerized"
BACKUP_BASE="/backup/mailcow/daily"
DATE=$(date +%F)
TMP="/tmp/mailcow-backup-$DATE"
ARCHIVE="mailcow-$DATE.tar.gz"
PASSWORD_FILE="/opt/mailcow-dockerized/.backup_pass"

mkdir -p "$TMP" "$BACKUP_BASE"

echo "📦 Backup Mailcow started ($DATE)"

# 1️⃣ Dump MySQL
docker exec mysql-mailcow \
  mysqldump -u root -p$(grep DBROOT mailcow.conf | cut -d= -f2) mailcow \
  > "$TMP/mysql.sql"

# 2️⃣ Copy volumes
cp -a data/vmail "$TMP/"
cp -a data/dkim "$TMP/"
cp -a data/sieve "$TMP/"
cp mailcow.conf "$TMP/"

# 3️⃣ Create archive
tar -czf "/tmp/$ARCHIVE" -C "$TMP" .

# 4️⃣ Encrypt archive
openssl enc -aes-256-cbc -salt \
  -in "/tmp/$ARCHIVE" \
  -out "$BACKUP_BASE/$ARCHIVE.enc" \
  -pass file:$PASSWORD_FILE

# 5️⃣ Cleanup
rm -rf "$TMP" "/tmp/$ARCHIVE"

echo "✅ Backup completed: $ARCHIVE.enc"
```

---

# 🔑 STEP 2 — BUAT PASSWORD BACKUP

```bash
openssl rand -base64 32 > /opt/mailcow-dockerized/.backup_pass
chmod 600 /opt/mailcow-dockerized/.backup_pass
```

⚠️ **SIMPAN PASSWORD INI DI TEMPAT AMAN**

---

# ⏱️ STEP 3 — CRON JOB (OTOMATIS)

Edit cron:

```bash
crontab -e
```

### Backup harian jam 02:00

```cron
0 2 * * * /opt/mailcow-dockerized/scripts/backup-mailcow.sh >> /var/log/mailcow-backup.log 2>&1
```

---

# 🔁 STEP 4 — ROTASI BACKUP (AUTO CLEANUP)

Tambahkan script:

### 📄 `/opt/mailcow-dockerized/scripts/cleanup-backup.sh`

```bash
#!/bin/bash
find /backup/mailcow/daily -type f -mtime +7 -delete
find /backup/mailcow/weekly -type f -mtime +30 -delete
find /backup/mailcow/monthly -type f -mtime +180 -delete
```

Cron:

```cron
30 2 * * * /opt/mailcow-dockerized/scripts/cleanup-backup.sh
```

---

# ☁️ STEP 5 — OFFSITE BACKUP (SANGAT DISARANKAN)

### Contoh ke S3 / Wasabi (rclone)

```bash
rclone sync /backup/mailcow s3:mail-backup/mailcow --progress
```

Cron:

```cron
0 3 * * * rclone sync /backup/mailcow s3:mail-backup/mailcow
```

---

# ♻️ RESTORE (PALING PENTING)

## 🔄 FULL RESTORE

```bash
openssl enc -d -aes-256-cbc \
  -in mailcow-2025-01-15.tar.gz.enc \
  -out restore.tar.gz \
  -pass file:.backup_pass

tar -xzf restore.tar.gz
```

Restore data:

```bash
cp -a vmail data/
cp -a dkim data/
cp -a sieve data/
cp mailcow.conf .
```

Restore DB:

```bash
docker exec -i mysql-mailcow mysql -u root -p mailcow < mysql.sql
```

Restart:

```bash
docker compose down
docker compose up -d
```

---

## 📬 RESTORE 1 MAILBOX SAJA

Mail berada di:

```
data/vmail/example.com/user/
```

Copy folder user → restart dovecot.

---

# 🚨 MONITORING (OPTIONAL)

Tambahkan alert jika backup gagal:

```bash
|| curl -X POST https://api.telegram.org/botTOKEN/sendMessage \
   -d chat_id=CHATID -d text="❌ Mailcow backup FAILED"
```

---

# 🏆 HASIL AKHIR

✔️ Backup otomatis
✔️ Encrypted
✔️ Rotasi
✔️ Offsite ready
✔️ Restore granular
