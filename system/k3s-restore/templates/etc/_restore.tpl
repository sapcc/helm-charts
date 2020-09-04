#!/usr/bin/env bash

# Copy the exact backup folder name from S3
BACKUP={{ required ".Values.job.backup is required" .Values.job.backup }}
BACKUPDIR=/root/backup/$BACKUP

mkdir -p $BACKUPDIR

aws s3 sync s3://$AWS_BUCKET/$BACKUP $BACKUPDIR
ls -la $BACKUPDIR

cp -r $BACKUPDIR/rancher /host/etc/
cp -r $BACKUPDIR/server /host/var/lib/rancher/k3s/

cd /host/var/lib/rancher/k3s/server/db
cp $BACKUPDIR/state.backup.db state.backup.db
sqlite3 state.db ".restore state.backup.db"
rm state.backup.db
