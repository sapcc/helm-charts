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

# handle aws s3 sync exit_code=2 (partial upload)
if aws s3 sync "$BACKUPDIR" "s3://$AWS_BUCKET/$BACKUP/"
then
    exit_code=0
else
    exit_code=$?
fi

echo "aws s3 sync exit code: $exit_code"

case $exit_code in
1)
    echo "S3 Sync failed"
    exit $exit_code
    ;;
2)
    echo "S3 sync complete with warnings (see log above)"
    ;;
*)
    echo "Unexpected exit code: $exit_code"
    exit $exit_code
    ;;
esac

touch $BACKUPDIR/latest
echo $BACKUP > $BACKUPDIR/latest
aws s3 cp $BACKUPDIR/latest s3://$AWS_BUCKET/

# cleanup backupdir
rm -rf $BACKUPDIR

echo "Backup complete"
