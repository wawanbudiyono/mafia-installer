#!/bin/bash

set -e

echo "========================================="
echo "      Mafia Installer v1.0"
echo "========================================="

if [ "$EUID" -ne 0 ]; then
    echo "Jalankan sebagai root!"
    exit 1
fi

echo ""
read -p "WebDAV Username : " WEBDAV_USER
read -s -p "WebDAV Password : " WEBDAV_PASS
echo ""
read -p "Cloudflare Tunnel Token : " CF_TOKEN

echo ""
echo "==> Install Docker"

apt update

apt install -y \
docker.io \
docker-compose-plugin \
curl \
fuse3 \
rclone

systemctl enable docker
systemctl start docker

mkdir -p /mnt/storage/compose/filebrowser
mkdir -p /mnt/storage/compose/webdav
mkdir -p /mnt/storage/compose/cloudflared

cp compose/filebrowser.yaml /mnt/storage/compose/filebrowser/compose.yaml
cp compose/webdav.yaml /mnt/storage/compose/webdav/compose.yaml
cp compose/cloudflared.yaml /mnt/storage/compose/cloudflared/compose.yaml

sed -i "s/WEB_USER/$WEBDAV_USER/g" /mnt/storage/compose/webdav/compose.yaml
sed -i "s/WEB_PASS/$WEBDAV_PASS/g" /mnt/storage/compose/webdav/compose.yaml
sed -i "s|YOUR_TOKEN|$CF_TOKEN|g" /mnt/storage/compose/cloudflared/compose.yaml

echo ""
echo "==> Deploy FileBrowser"

cd /mnt/storage/compose/filebrowser
docker compose up -d

echo ""
echo "==> Deploy WebDAV"

cd /mnt/storage/compose/webdav
docker compose up -d

echo ""
echo "==> Deploy Cloudflared"

cd /mnt/storage/compose/cloudflared
docker compose up -d

echo ""
read -p "Install Google Drive? (y/n) : " GDRIVE

if [ "$GDRIVE" = "y" ]; then

    rclone config

    cp systemd/rclone-gdrive.service /etc/systemd/system/

    systemctl daemon-reload

    systemctl enable rclone-gdrive

    systemctl restart rclone-gdrive

fi

echo ""
echo "========================================="
echo "INSTALL SELESAI"
echo "========================================="