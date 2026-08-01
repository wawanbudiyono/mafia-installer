#!/bin/bash

DATE=$(date +%Y%m%d-%H%M)

mkdir -p /mnt/storage/backup/$DATE

cp -r /mnt/storage/compose /mnt/storage/backup/$DATE/

cp ~/.config/rclone/rclone.conf \
/mnt/storage/backup/$DATE/ 2>/dev/null || true

cp /etc/systemd/system/rclone-gdrive.service \
/mnt/storage/backup/$DATE/

echo "Backup selesai."