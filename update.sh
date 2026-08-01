#!/bin/bash

set -e

echo "========================================="
echo "      Mafia Installer Update"
echo "========================================="

git pull

echo ""
echo "==> Update Docker Images"

for APP in filebrowser webdav cloudflared
do
    if [ -d "/mnt/storage/compose/$APP" ]; then
        cd /mnt/storage/compose/$APP
        docker compose pull
        docker compose up -d
    fi
done

echo ""
echo "==> Restart Google Drive"

if systemctl is-enabled rclone-gdrive >/dev/null 2>&1; then
    systemctl restart rclone-gdrive
fi

echo ""
echo "==> Cleanup"

docker image prune -f

echo ""
docker ps

echo ""
echo "========================================="
echo " Update Selesai "
echo "========================================="