#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

clear

echo "========================================="
echo "      Mafia Installer v2"
echo "========================================="

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
echo "==> Deploy FileBrowser"

cd /mnt/storage/compose/filebrowser

$COMPOSE pull
$COMPOSE up -d

echo ""
echo "==> Deploy WebDAV"

cd /mnt/storage/compose/webdav

$COMPOSE pull
$COMPOSE up -d

echo ""
echo "==> Deploy Cloudflared"

cd /mnt/storage/compose/cloudflared

$COMPOSE pull
$COMPOSE up -d

cd "$SCRIPT_DIR"

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

fi

echo ""
echo "========================================="
echo " INSTALL SELESAI "
echo "========================================="

echo ""

docker ps

echo ""

echo "========================================="
echo " FileBrowser : http://IP:8080"
echo " WebDAV      : http://IP:8081"
echo "========================================="