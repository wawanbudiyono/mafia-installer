# Mafia Installer

Installer sederhana untuk server pribadi.

## 1. Clone Repository

```bash
git clone https://github.com/wawanbudiyono/mafia-installer.git
cd mafia-installer
```

---

## 2. Beri Hak Eksekusi

```bash
chmod +x install.sh
chmod +x update.sh
chmod +x backup.sh
```

---

## 3. Jalankan Installer

```bash
sudo ./install.sh
```

Installer akan meminta:

- WebDAV Username
- WebDAV Password
- Cloudflare Tunnel Token
- Konfigurasi Google Drive (Opsional)

---

## 4. Update

Jika ada update installer:

```bash
git pull
sudo ./update.sh
```

---

## 5. Backup

Membuat backup konfigurasi:

```bash
sudo ./backup.sh
```

---

## Service

### FileBrowser

```
http://IP_SERVER:8080
```

### WebDAV

```
http://IP_SERVER:8081
```

### Google Drive

```
/mnt/storage/data/GoogleDrive
```

---

## Cek Status

Docker

```bash
docker ps
```

Google Drive

```bash
systemctl status rclone-gdrive
```

---

## Restart Service

Google Drive

```bash
systemctl restart rclone-gdrive
```

FileBrowser

```bash
cd /mnt/storage/compose/filebrowser
docker compose restart
```

WebDAV

```bash
cd /mnt/storage/compose/webdav
docker compose restart
```

Cloudflared

```bash
cd /mnt/storage/compose/cloudflared
docker compose restart
```