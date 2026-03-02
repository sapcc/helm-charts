#!/usr/bin/env bash
set -euo pipefail

BACKUP=Backup-$(date +"%Y-%m-%d-%H%M%S")
BACKUPDIR=/root/backup/$BACKUP

# backup regular files
mkdir -p $BACKUPDIR
cp -r /host/etc/rancher/ $BACKUPDIR
cp -r /host/var/lib/rancher/k3s/server $BACKUPDIR

# do SQL backup
cd /host/var/lib/rancher/k3s/server/db
sqlite3 state.db ".backup state.backup.db"

# upload backup
mv state.backup.db $BACKUPDIR
ls -la $BACKUPDIR
aws s3 sync /root/backup/ s3://$AWS_BUCKET/
touch $BACKUPDIR/latest
echo $BACKUP > $BACKUPDIR/latest
aws s3 cp $BACKUPDIR/latest s3://$AWS_BUCKET/

# cleanup backupdir
rm -rf $BACKUPDIR
