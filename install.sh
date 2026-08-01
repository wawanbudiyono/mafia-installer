#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IP=$(hostname -I | awk '{print $1}')

clear

cat << "EOF"

███╗   ██╗ █████╗ ███████╗
████╗  ██║██╔══██╗██╔════╝
██╔██╗ ██║███████║███████╗
██║╚██╗██║██╔══██║╚════██║
██║ ╚████║██║  ██║███████║
╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝

███╗   ███╗ █████╗ ███████╗██╗ █████╗
████╗ ████║██╔══██╗██╔════╝██║██╔══██╗
██╔████╔██║███████║█████╗  ██║███████║
██║╚██╔╝██║██╔══██║██╔══╝  ██║██╔══██║
██║ ╚═╝ ██║██║  ██║██║     ██║██║  ██║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝

        NAS Mafia Teknik
        Installer v2.1

EOF

if [ "$EUID" -ne 0 ]; then
    echo "Jalankan installer sebagai root."
    exit 1
fi

echo ""
echo "==> Cek Sistem"

if ! command -v apt >/dev/null 2>&1; then
    echo "Installer hanya mendukung Debian / Ubuntu."
    exit 1
fi

echo ""
echo "==> Cek Koneksi Internet"

if ! ping -c1 8.8.8.8 >/dev/null 2>&1; then
    echo "Internet tidak tersedia."
    exit 1
fi

echo "Internet OK"

echo ""
echo "==> Update Repository"

apt update

echo ""
echo "==> Install Package"

apt install -y \
docker.io \
docker-compose \
curl \
wget \
git \
fuse3 \
ca-certificates \
rclone

systemctl enable docker
systemctl start docker

if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    echo "Docker Compose tidak ditemukan!"
    exit 1
fi

echo ""
echo "==> Membuat Folder"

mkdir -p /mnt/storage/data
mkdir -p /mnt/storage/data/GoogleDrive
mkdir -p /mnt/storage/appdata/filebrowser

mkdir -p /mnt/storage/compose/filebrowser
mkdir -p /mnt/storage/compose/webdav
mkdir -p /mnt/storage/compose/cloudflared

echo ""
read -s -p "FileBrowser Password : " FB_PASS
echo

read -p "WebDAV Username : " WEBDAV_USER

read -s -p "WebDAV Password : " WEBDAV_PASS
echo

read -p "Cloudflare Tunnel Token : " CF_TOKEN

echo ""
echo "==> Copy Compose"

cp "$SCRIPT_DIR/compose/filebrowser.yaml" \
/mnt/storage/compose/filebrowser/compose.yaml

cp "$SCRIPT_DIR/compose/webdav.yaml" \
/mnt/storage/compose/webdav/compose.yaml

cp "$SCRIPT_DIR/compose/cloudflared.yaml" \
/mnt/storage/compose/cloudflared/compose.yaml

sed -i "s/WEB_USER/$WEBDAV_USER/g" \
/mnt/storage/compose/webdav/compose.yaml

sed -i "s/WEB_PASS/$WEBDAV_PASS/g" \
/mnt/storage/compose/webdav/compose.yaml

sed -i "s|YOUR_TOKEN|$CF_TOKEN|g" \
/mnt/storage/compose/cloudflared/compose.yaml

echo ""
echo "[1/3] Deploy FileBrowser"

cd /mnt/storage/compose/filebrowser

$COMPOSE pull
$COMPOSE up -d

echo ""
echo "Menunggu FileBrowser siap..."

sleep 5

docker exec filebrowser \
filebrowser users update admin \
--password "$FB_PASS"

echo "✓ Password FileBrowser berhasil diatur"

echo ""
echo "[2/3] Deploy WebDAV"

cd /mnt/storage/compose/webdav

$COMPOSE pull
$COMPOSE up -d

echo ""
echo "[3/3] Deploy Cloudflared"

cd /mnt/storage/compose/cloudflared

$COMPOSE pull
$COMPOSE up -d

cd "$SCRIPT_DIR"

echo ""
echo "✓ Semua container berhasil dijalankan."

echo ""
read -p "Install Google Drive? (y/n) : " GDRIVE

if [[ "$GDRIVE" =~ ^[Yy]$ ]]; then

    echo ""

    if rclone listremotes | grep -q "^gdrive:$"; then
        echo "Google Drive sudah dikonfigurasi."
    else
        echo "======================================"
        echo " Konfigurasi Google Drive"
        echo "======================================"

        rclone config
    fi

    cp "$SCRIPT_DIR/systemd/rclone-gdrive.service" \
    /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable rclone-gdrive
    systemctl restart rclone-gdrive

else

    echo ""
    echo "Google Drive dilewati."

fi

echo ""
echo "========================================="
echo " Status Container"
echo "========================================="

docker ps --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "========================================="
echo " INSTALL BERHASIL "
echo "========================================="

echo ""
echo "IP Address      : $IP"
echo ""
echo "FileBrowser     : http://$IP:8080"
echo "WebDAV          : http://$IP:8081"
echo ""
echo "Folder Storage  : /mnt/storage/data"
echo "Compose Folder  : /mnt/storage/compose"
echo ""
echo "Terima kasih telah menggunakan"
echo "NAS Mafia Teknik Installer"
echo "========================================="